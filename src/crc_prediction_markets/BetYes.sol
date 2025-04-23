// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IFixedProductMarketMaker.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "circles-v2/hub/Hub.sol";
import "circles-v2/lift/IERC20Lift.sol";

import {console} from "forge-std/console.sol";

contract BetYesContract is ERC1155Holder {
    IFixedProductMarketMaker public immutable fpmm;
    //ERC20 public immutable groupCRCToken;
    uint256 public immutable outcomeIndex;
    Hub public hub;
    address groupCRCToken;

    //ToDo - balance per user for later redeem

    constructor(address fpmmAddress, address _groupCRCToken, uint256 _outcomeIndex, address _hubAddress) {
        fpmm = IFixedProductMarketMaker(fpmmAddress);
        groupCRCToken = _groupCRCToken;
        outcomeIndex = _outcomeIndex;
        hub = Hub(_hubAddress);
    }

    function placeBet(uint256 investmentAmount) public {
        // Wrap received tokens
        console.log("entered placebet, groupCRCToken", address(groupCRCToken));
        // not needed
        address erc20Group = hub.wrap(address(groupCRCToken), investmentAmount, CirclesType.Inflation);
        console.log("erc20group inside placebet", address(erc20Group));

        // authorize groupCRC
        console.log("1 place bet, investmentAmount", investmentAmount);
        uint256 allowance = ERC20(erc20Group).allowance(address(this), address(fpmm));
        console.log("allowance", allowance);
        if (allowance < investmentAmount) {
            ERC20(erc20Group).approve(address(fpmm), investmentAmount);
        }
        console.log("allowance after approve", allowance);

        console.log("fpmm", address(fpmm));
        uint256 expectedShares = fpmm.calcBuyAmount(investmentAmount, outcomeIndex);
        console.log("expected shares", expectedShares);
        // 1% slippage
        uint256 balance = ERC20(fpmm.collateralToken()).balanceOf(address(this));
        console.log("collateral balance", balance);
        fpmm.buy(investmentAmount, outcomeIndex, expectedShares * 99 / 100);
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes memory data)
        public
        virtual
        override
        returns (bytes4)
    {
        console.log("entered onERC1155Received", id, value);

        placeBet(value);
        console.log("after placeBet");
        return super.onERC1155Received(operator, from, id, value, data);
    }
}
