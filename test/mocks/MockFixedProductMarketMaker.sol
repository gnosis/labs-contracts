// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

//import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "circles-v2/circles/ERC1155.sol";
import "circles-v2-test/groups/groupSetup.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MockConditionalTokens.sol";
import "../../src/crc_prediction_markets/CTHelpers.sol";

contract MockFixedProductMarketMaker is ERC20 {
    event FPMMBuy(
        address indexed buyer,
        uint256 investmentAmount,
        uint256 feeAmount,
        uint256 indexed outcomeIndex,
        uint256 outcomeTokensBought
    );

    address public collateralToken;
    uint256 public outcomeSlotCount;
    bytes32 public conditionId;
    MockConditionalTokens public conditionalTokens;
    mapping(uint256 => uint256) public outcomePrices;
    mapping(address => uint256) public feesWithdrawable;

    constructor(address _collateralToken, uint256 _outcomeSlotCount, bytes32 _conditionId) ERC20("MockFPMM", "MFPMM") {
        collateralToken = _collateralToken;
        outcomeSlotCount = _outcomeSlotCount;
        conditionId = _conditionId;
        conditionalTokens = new MockConditionalTokens();
    }

    // View functions

    function calcBuyAmount(uint256 amount, uint256 outcomeIndex) external view returns (uint256) {
        require(outcomeIndex < outcomeSlotCount, "Invalid outcome index");
        // Simple mock calculation - 5% fee
        return amount * 95 / 100;
    }

    // External state-changing functions

    function buy(uint256 amount, uint256 outcomeIndex, uint256 minShares) external {
        require(outcomeIndex < outcomeSlotCount, "Invalid outcome index");
        require(amount > 0, "Amount must be greater than 0");

        // Transfer collateral from buyer
        IERC20(collateralToken).transferFrom(msg.sender, address(this), amount);

        // Calculate shares (5% fee)
        uint256 shares = amount * 95 / 100;
        require(shares >= minShares, "Insufficient shares");

        // Update outcome prices
        outcomePrices[outcomeIndex] += shares;

        // Here we would transfer the outcome tokens to the user, but not doing it here since not needed by the test.

        // Emit event
        emit FPMMBuy(msg.sender, amount, amount * 5 / 100, outcomeIndex, shares);
    }

    function addFunding(uint256 addedFunds, uint256[] calldata) external {
        // we mock parts of the inner workings from https://github.com/gnosis/conditional-tokens-market-makers/blob/master/contracts/FixedProductMarketMaker.sol#L148

        require(addedFunds > 0, "funding must be non-zero");
        require(IERC20(collateralToken).transferFrom(msg.sender, address(this), addedFunds), "funding transfer failed");

        // this amount is not correct, but we mock it as so.
        _mint(msg.sender, addedFunds);
    }

    function removeFunding(uint256 sharesToBurn) external {
        _burn(msg.sender, sharesToBurn);
        // transfer outcome tokens
        uint256[] memory tokenIds = getTokenIds(collateralToken);
        for (uint256 index = 0; index < tokenIds.length; index++) {
            conditionalTokens.mint(address(this), tokenIds[index], sharesToBurn);
            // in reality, this should be `safeBatchTransferFrom`, but here we mock it as so.
            conditionalTokens.safeTransferFrom(address(this), msg.sender, tokenIds[index], sharesToBurn, "");
        }
    }

    // Convenience function
    function getTokenIds(address collateralTokenAddress) public view returns (uint256[] memory) {
        IERC20 collateralTokenAsERC20 = IERC20(collateralTokenAddress);
        uint256[] memory tokenIds = new uint256[](2);
        for (uint256 j = 0; j < 2; j++) {
            bytes32 collectionId = CTHelpers.getCollectionId(bytes32(0), conditionId, j + 1);
            uint256 positionId = CTHelpers.getPositionId(collateralTokenAsERC20, collectionId);
            tokenIds[j] = positionId;
        }

        return tokenIds;
    }
}
