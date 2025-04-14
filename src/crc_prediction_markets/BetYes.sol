// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IFixedProductMarketMaker.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "forge-std/console.sol";

contract BetYesContract is ERC1155Holder {
    IFixedProductMarketMaker public immutable fpmm;
    ERC20 public immutable groupCRCToken;
    uint256 public immutable outcomeIndex;

    constructor(address fpmmAddress, address _groupCRCToken, uint256 _outcomeIndex) {
        fpmm = IFixedProductMarketMaker(fpmmAddress);
        groupCRCToken = ERC20(_groupCRCToken);
        outcomeIndex = _outcomeIndex;

        groupCRCToken.approve(fpmmAddress, type(uint256).max);
    }

    event DummyTriggered(uint256 tokenId, uint256 value);

    function dummy(uint256 tokenId, uint256 value) internal {
        emit DummyTriggered(tokenId, value);
    }

    function placeBet(uint256 investmentAmount) public {
        // authorize groupCRC
        console.log("1 place bet, investmentAmount", investmentAmount);
        uint256 allowance = groupCRCToken.allowance(address(this), address(fpmm));
        console.log("allowance", allowance);

        console.log("fpmm", address(fpmm));
        uint256 expectedShares = fpmm.calcBuyAmount(investmentAmount, outcomeIndex);
        console.log("expected shares", expectedShares);
        // 1% slippage
        uint256 balance = ERC20(fpmm.collateralToken()).balanceOf(address(this));
        console.log("wxdai balance", balance);
        fpmm.buy(investmentAmount, outcomeIndex, expectedShares * 99 / 100);
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes memory data)
        public
        virtual
        override
        returns (bytes4)
    {
        // ToDo - filter by ID properly (set constructor)
        if (id == 1) placeBet(value);

        return super.onERC1155Received(operator, from, id, value, data);
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) public virtual override returns (bytes4) {
        for (uint256 i = 0; i < ids.length; i++) {
            dummy(ids[i], values[i]);
        }
        return super.onERC1155BatchReceived(operator, from, ids, values, data);
    }
}
