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

/**
 * @title LiquidityManager
 * @dev Manages liquidity provisioning to FixedProductMarketMaker contracts
 */
contract LiquidityAdder is ERC1155Holder {
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

    uint256 public slotCount;

    // Responsible for managing balances externally
    LiquidityVaultToken public liquidityVaultToken;

    // Events
    event LiquidityAdded(address indexed provider, uint256 amount, uint256 sharesMinted);
    event LiquidityRemoved(address indexed provider, uint256 collateralAmount, uint256 sharesBurned);

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
        uint256 _slotCount
    ) {
        require(_marketMaker != address(0), "Invalid market maker address");
        require(_hubAddress != address(0), "Invalid hub address");
        require(_groupCRCToken != address(0), "Invalid group CRC token address");
        require(_liquidityVaultToken != address(0), "Invalid liquidity vault token address");

        marketMaker = IFixedProductMarketMaker(_marketMaker);
        collateralToken = IERC20(marketMaker.collateralToken());
        hub = Hub(_hubAddress);
        groupCRCToken = _groupCRCToken;
        liquidityVaultToken = LiquidityVaultToken(_liquidityVaultToken);
        slotCount = _slotCount;

        // Wrap the collateral token for ERC1155 support
        wrappedCollateralToken = hub.wrap(address(collateralToken), 0, CirclesType.Inflation);

        // Approve the wrapped token for transfers
        collateralToken.approve(address(hub), type(uint256).max);
    }

    function addLiquidity(uint256 amount, address better) internal returns (uint256) {
        require(amount > 0, "Amount must be greater than 0");
        require(better != address(0), "Invalid better address");

        uint256 amountToBet = BettingUtils.defineAmountToBet(
            hub, wrappedCollateralToken, address(groupCRCToken), amount, CirclesType.Inflation
        );
        uint256[] memory distributionHint = new uint256[](slotCount);

        // We add liquidity in equal amounts to all outcomes
        // Hence no need to fill distributionHint

        marketMaker.addFunding(amountToBet, distributionHint);

        // Calculate shares minted
        // Shares stay on the LiquidityAdder contract - on a per-user level, tracked by LiquidityVaultToken
        uint256 shares = marketMaker.balanceOf(address(this));
        liquidityVaultToken.mintTo(better, address(marketMaker), shares, "");

        emit LiquidityAdded(better, amountToBet, shares);
        return shares;
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes memory data)
        public
        virtual
        override
        returns (bytes4)
    {
        // Only process if the received token is our wrapped collateral token
        // We only place bet if we received groupCRC tokens
        if (groupCRCToken == address(uint160(id))) {
            addLiquidity(value, from);
        }

        return super.onERC1155Received(operator, from, id, value, data);
    }
}
