// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./IFixedProductMarketMaker.sol";
import "circles-contracts-v2/hub/Hub.sol";
import "circles-contracts-v2/lift/IERC20Lift.sol";
import "./utils/BettingUtils.sol";
import "./LiquidityVaultToken.sol";
import "./BetContractFactory.sol";
import "./BetContract.sol";
import "./CTHelpers.sol";

/**
 * @title LiquidityRemover
 * @dev Manages liquidity removal from FixedProductMarketMaker contracts
 */
contract LiquidityRemover is ERC1155Holder {
    using SafeERC20 for IERC20;

    // Address of the FixedProductMarketMaker contract
    IFixedProductMarketMaker public immutable marketMaker;

    // The collateral token used by the market
    IERC20 public immutable collateralToken;

    // The wrapped ERC20 token address for the collateral
    address public wrappedCollateralToken;

    // The Circles Hub contract
    Hub public immutable hub;

    address public groupCRCToken;

    // conditionIds from the marketMaker
    bytes32[] public conditionIds;

    // Responsible for managing balances externally
    LiquidityVaultToken public liquidityVaultToken;

    BetContractFactory public betContractFactory;

    // Events
    event LiquidityRemoved(address indexed provider, uint256 amount, uint256 sharesBurned);

    /**
     * @dev Constructor initializes the LiquidityManager with the market maker address
     * @param _marketMaker Address of the FixedProductMarketMaker contract
     */
    /**
     * @dev Constructor initializes the LiquidityManager with the market maker and hub addresses
     * @param _marketMaker Address of the FixedProductMarketMaker contract
     * @param _hubAddress Address of the Circles Hub contract
     */
    constructor(
        address _marketMaker,
        address _hubAddress,
        address _groupCRCToken,
        address _liquidityVaultToken,
        address _betContractFactory,
        bytes32[] memory _conditionIds
    ) {
        require(_marketMaker != address(0), "Invalid market maker address");
        require(_hubAddress != address(0), "Invalid hub address");
        require(_groupCRCToken != address(0), "Invalid group CRC token address");
        require(_liquidityVaultToken != address(0), "Invalid liquidity vault token address");
        require(conditionIds.length > 0, "No conditions found");

        marketMaker = IFixedProductMarketMaker(_marketMaker);
        collateralToken = IERC20(marketMaker.collateralToken());
        hub = Hub(_hubAddress);
        groupCRCToken = _groupCRCToken;
        liquidityVaultToken = LiquidityVaultToken(_liquidityVaultToken);
        betContractFactory = BetContractFactory(_betContractFactory);
        conditionIds = _conditionIds;

        // Wrap the collateral token for ERC1155 support
        wrappedCollateralToken = hub.wrap(address(collateralToken), 0, CirclesType.Inflation);

        // Approve the wrapped token for transfers
        collateralToken.approve(address(hub), type(uint256).max);
    }

    function removeAllLiquidityFromUser(address user) internal {
        uint256 shares = liquidityVaultToken.balanceOf(user, liquidityVaultToken.parseAddress(address(marketMaker)));
        require(shares > 0, "Insufficient balance");
        liquidityVaultToken.burnFrom(user, address(marketMaker), shares);
        marketMaker.removeFunding(shares);

        IConditionalTokens conditionalTokens = IConditionalTokens(address(marketMaker.conditionalTokens()));

        // Get all bet contracts for this market
        MarketInfo memory marketInfo = betContractFactory.getMarketInfo(address(marketMaker));
        uint256 numBetContracts = marketInfo.betContracts.length;
        require(numBetContracts > 0, "No bet contracts found");

        // Convert addresses to BetContract instances
        BetContract[] memory betContracts = new BetContract[](numBetContracts);
        for (uint256 i = 0; i < numBetContracts; i++) {
            betContracts[i] = BetContract(marketInfo.betContracts[i]);
        }

        // For each condition and outcome, transfer the corresponding tokens
        // ToDo - Loop through outcomeSlot count
        for (uint256 i = 0; i < conditionIds.length; i++) {
            for (uint256 j = 0; j < betContracts.length; j++) {
                bytes32 conditionId = conditionIds[i];
                bytes32 collectionId = CTHelpers.getCollectionId(
                    bytes32(0), conditionId, CTHelpers.getPositionId(IERC20(marketMaker.collateralToken()), bytes32(0))
                );

                // j+1 denotes the index set (starts at 1)
                uint256 positionId = CTHelpers.getPositionId(
                    IERC20(marketMaker.collateralToken()), CTHelpers.getCollectionId(collectionId, conditionId, j + 1)
                );

                uint256 balance = conditionalTokens.balanceOf(address(this), positionId);
                if (balance > 0) {
                    bytes memory data = abi.encode(user, shares);
                    conditionalTokens.safeTransferFrom(
                        address(this), address(betContracts[i]), positionId, balance, data
                    );
                }
            }
        }

        // Ensures any remaining collateral is sent to the user
        uint256 collateralBalance = IERC20(marketMaker.collateralToken()).balanceOf(address(this));
        if (collateralBalance > 0) {
            IERC20(marketMaker.collateralToken()).transfer(user, collateralBalance);
        }

        emit LiquidityRemoved(user, collateralBalance, shares);
    }

    /**
     * @dev ERC1155 token received hook
     * @notice Called when ERC1155 tokens are transferred to this contract
     * @param operator The address which called the function
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes memory data)
        public
        virtual
        override
        returns (bytes4)
    {
        // Only process if the received token is our wrapped collateral token
        // We only place bet if we received groupCRC tokens
        if (groupCRCToken == address(uint160(id))) {
            removeAllLiquidityFromUser(from);
        }

        return super.onERC1155Received(operator, from, id, value, data);
    }
}
