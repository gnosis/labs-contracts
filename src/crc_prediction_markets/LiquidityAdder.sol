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
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "forge-std/console.sol";

contract LiquidityAdder is ERC1155Holder, ReentrancyGuard, BettingUtils {
    using SafeERC20 for IERC20;

    address public immutable marketMakerAddress;

    // The collateral token used by the market
    address public immutable collateralTokenAddress;

    // The Circles Hub contract
    Hub public immutable hub;

    address public groupCRCToken;

    uint256 public slotCount;

    // Responsible for managing balances externally
    LiquidityVaultToken public liquidityVaultToken;

    // Events
    event LiquidityAdded(address indexed provider, uint256 amount, uint256 sharesMinted);

    constructor(
        address _marketMaker,
        address _hubAddress,
        address _collateralToken,
        address _groupCRCToken,
        address _liquidityVaultToken,
        uint256 _slotCount,
        string memory _organizationName,
        bytes32 _organizationMetadataDigest
    ) {
        marketMakerAddress = _marketMaker;
        collateralTokenAddress = _collateralToken;
        hub = Hub(_hubAddress);
        groupCRCToken = _groupCRCToken;
        liquidityVaultToken = LiquidityVaultToken(_liquidityVaultToken);
        slotCount = _slotCount;

        hub.registerOrganization(_organizationName, _organizationMetadataDigest);
        // This assures that this contract always receives group CRC tokens.
        hub.trust(_groupCRCToken, type(uint96).max);
    }

    function _ensureApproval(uint256 amount) private {
        IERC20 collateralToken = IERC20(collateralTokenAddress);
        uint256 allowance = collateralToken.allowance(address(this), marketMakerAddress);
        if (allowance < amount) {
            collateralToken.approve(marketMakerAddress, amount);
        }
    }

    function addLiquidity(uint256 amount, address better) private nonReentrant returns (uint256) {
        uint256 amountToBet = BettingUtils.defineAmountToBet(
            address(hub), collateralTokenAddress, groupCRCToken, amount, CirclesType.Inflation
        );
        uint256[] memory distributionHint = new uint256[](0);

        _ensureApproval(amountToBet);

        // We add liquidity in equal amounts to all outcomes, hence no need to fill distributionHint
        // We transfer the LP tokens to the liquidity vault token contract for safekeeping
        IERC20 marketMakerTokenAsToken = IERC20(marketMakerAddress);
        uint256 prevBalance = marketMakerTokenAsToken.balanceOf(address(this));
        console.log("prevBalance", prevBalance);
        console.log("distri hint length", distributionHint.length);
        console.logAddress(marketMakerAddress);
        IFixedProductMarketMaker(marketMakerAddress).addFunding(amountToBet, distributionHint);
        uint256 postBalance = marketMakerTokenAsToken.balanceOf(address(this));
        marketMakerTokenAsToken.transfer(address(liquidityVaultToken), postBalance - prevBalance);

        uint256 shares = IFixedProductMarketMaker(marketMakerAddress).balanceOf(address(liquidityVaultToken));
        console.log("shares alice", shares);
        liquidityVaultToken.mintTo(better, marketMakerAddress, shares, "");

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
        if (msg.sender == address(hub) && groupCRCToken == address(uint160(id))) {
            addLiquidity(value, from);
        }

        return super.onERC1155Received(operator, from, id, value, data);
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual override returns (bytes4) {
        // Process each token in the batch individually leveraging the single-transfer logic
        for (uint256 i = 0; i < ids.length; i++) {
            onERC1155Received(operator, from, ids[i], values[i], data);
        }
        return super.onERC1155BatchReceived(operator, from, ids, values, data);
    }
}
