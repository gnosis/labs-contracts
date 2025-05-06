// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IFixedProductMarketMaker.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "circles-v2/hub/Hub.sol";
import "circles-v2/lift/IERC20Lift.sol";

import {console} from "forge-std/console.sol";

contract BetYesContract is ERC1155Holder {
    IFixedProductMarketMaker public immutable fpmm;
    //ERC20 public immutable groupCRCToken;
    uint256 public immutable outcomeIndex;
    Hub public hub;
    address groupCRCToken;
    address immutable erc20Group;

    // outcome token balances
    mapping(address => uint256) public balances;

    //ToDo - add balance per user for later redeem

    constructor(address fpmmAddress, address _groupCRCToken, uint256 _outcomeIndex, address _hubAddress) {
        fpmm = IFixedProductMarketMaker(fpmmAddress);
        groupCRCToken = _groupCRCToken;
        outcomeIndex = _outcomeIndex;
        hub = Hub(_hubAddress);
        erc20Group = hub.wrap(address(groupCRCToken), 0, CirclesType.Inflation);
        // ToDo - Add fpmm identifier
        string memory orgaName = "BetYes";
        hub.registerOrganization(orgaName, bytes32(0));
        // hub trusts group
        hub.trust(_groupCRCToken, type(uint96).max);
    }

    function getERC20Address(address groupToken) public returns (address) {
        return hub.wrap(groupToken, 0, CirclesType.Inflation);
    }

    function placeBet(uint256 investmentAmount, address better) public {
        // Wrap received tokens
        console.log("entered placebet, groupCRCToken", address(groupCRCToken));

        uint256 balanceBeforeWrap = ERC20(erc20Group).balanceOf(address(this));

        hub.wrap(address(groupCRCToken), investmentAmount, CirclesType.Inflation);
        console.log("erc20group inside placebet", address(erc20Group));
        // the balance will be greater than investmentAmount because demurrage not applied to inflationary tokens
        uint256 balanceAfterWrap = ERC20(erc20Group).balanceOf(address(this));
        console.log("balanceAfterWrap", balanceAfterWrap);
        uint256 amountToBet = balanceAfterWrap - balanceBeforeWrap;

        // authorize groupCRC
        console.log("1 place bet, amountToBet", amountToBet);
        uint256 allowance = ERC20(erc20Group).allowance(address(this), address(fpmm));
        console.log("allowance", allowance);
        if (allowance < amountToBet) {
            ERC20(erc20Group).approve(address(fpmm), amountToBet);
        }
        console.log("allowance after approve", allowance);

        console.log("fpmm", address(fpmm));
        uint256 expectedShares = fpmm.calcBuyAmount(amountToBet, outcomeIndex);
        console.log("expected shares", expectedShares);
        // 1% slippage
        uint256 balance = ERC20(fpmm.collateralToken()).balanceOf(address(this));
        console.log("collateral balance", balance);
        fpmm.buy(amountToBet, outcomeIndex, expectedShares * 99 / 100);
        // ToDo is this amount safe?
        balances[better] += expectedShares;
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes memory data)
        public
        virtual
        override
        returns (bytes4)
    {
        console.log("entered onERC1155Received", id, value);
        // We only place bet if we received groupCRC tokens
        if (groupCRCToken == address(uint160(id))) {
            placeBet(value, from);
            console.log("after placeBet");
        }

        console.log("end onERC1155Received");

        return super.onERC1155Received(operator, from, id, value, data);
    }
}
