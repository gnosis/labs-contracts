// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

//import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "circles-v2/circles/ERC1155.sol";
import "circles-v2-test/groups/groupSetup.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "forge-std/console.sol";

contract MockFixedProductMarketMaker {
    event FPMMBuy(
        address indexed buyer,
        uint256 investmentAmount,
        uint256 feeAmount,
        uint256 indexed outcomeIndex,
        uint256 outcomeTokensBought
    );

    address public collateralToken;
    uint256 public outcomeSlotCount;
    uint256 public conditionId;

    mapping(uint256 => uint256) public outcomePrices;
    mapping(address => uint256) public feesWithdrawable;

    constructor(address _collateralToken, uint256 _outcomeSlotCount, uint256 _conditionId) {
        collateralToken = _collateralToken;
        outcomeSlotCount = _outcomeSlotCount;
        conditionId = _conditionId;
    }

    // View functions

    function calcBuyAmount(uint256 amount, uint256 outcomeIndex) external view returns (uint256) {
        require(outcomeIndex < outcomeSlotCount, "Invalid outcome index");
        // Simple mock calculation - 5% fee
        return amount * 95 / 100;
    }

    // External state-changing functions

    function buy(uint256 amount, uint256 outcomeIndex, uint256 minShares) external {
        console.log("entered buy");
        require(outcomeIndex < outcomeSlotCount, "Invalid outcome index");
        require(amount > 0, "Amount must be greater than 0");

        // Transfer collateral from buyer
        console.log("before transfer");
        IERC20(collateralToken).transferFrom(msg.sender, address(this), amount);

        // Calculate shares (5% fee)
        console.log("calculating shares");
        uint256 shares = amount * 95 / 100;
        require(shares >= minShares, "Insufficient shares");

        // Update outcome prices
        console.log("updating outcome prices", shares);
        outcomePrices[outcomeIndex] += shares;

        // Transfer shares to buyer
        console.log("before transfer to buyer", shares);
        uint256 balanceOfContract = ERC20(collateralToken).balanceOf(address(this));
        console.log("balanceOfContract", balanceOfContract);
        // ToDo Add actual transfer via ConditionalTokens
        //ERC20(collateralToken).safeTransferFrom(address(this), msg.sender, outcomeIndex, shares, "");

        // Emit event
        console.log("before event is emitted");
        emit FPMMBuy(msg.sender, amount, amount * 5 / 100, outcomeIndex, shares);
    }
}
