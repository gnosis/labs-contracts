// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IFixedProductMarketMaker.sol";
import "./IConditionalTokens.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "circles-v2/hub/Hub.sol";
import "circles-v2/lift/IERC20Lift.sol";

import {console} from "forge-std/console.sol";

contract BetContract is ERC1155Holder, ReentrancyGuard {
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    event BetPlaced(address indexed better, uint256 investmentAmount, uint256 expectedShares);

    event Claimed(address indexed user, uint256 amount);

    IFixedProductMarketMaker public immutable fpmm;
    //ERC20 public immutable groupCRCToken;
    uint256 public immutable outcomeIndex;
    Hub public hub;
    address public groupCRCToken;
    address public erc20Group;

    // outcome token balances
    EnumerableMap.AddressToUintMap private _balances;
    uint256 private _totalSupply;

    mapping(address => uint256) public claimable;

    constructor(address fpmmAddress, address _groupCRCToken, uint256 _outcomeIndex, address _hubAddress) {
        require(fpmmAddress != address(0), "Invalid FPMM address");
        require(_groupCRCToken != address(0), "Invalid group CRC token address");
        require(_hubAddress != address(0), "Invalid hub address");

        fpmm = IFixedProductMarketMaker(fpmmAddress);
        groupCRCToken = _groupCRCToken;
        outcomeIndex = _outcomeIndex;

        hub = Hub(_hubAddress);

        erc20Group = hub.wrap(address(groupCRCToken), 0, CirclesType.Inflation);

        // ToDo - Add fpmm identifier
        string memory orgaName = "BetYes";
        hub.registerOrganization(orgaName, bytes32(0));
        // This assures that this contract always receives group CRC tokens.
        hub.trust(_groupCRCToken, type(uint96).max);
    }

    function getERC20Address(address groupToken) public returns (address) {
        return hub.wrap(groupToken, 0, CirclesType.Inflation);
    }

    function balanceOf(address account) public view returns (uint256) {
        (bool exists, uint256 balance) = _balances.tryGet(account);
        return exists ? balance : 0;
    }

    function getAddressesWithPositiveBalance() public view returns (address[] memory) {
        uint256 length = _balances.length();
        address[] memory addresses = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            (address addr, uint256 balance) = _balances.at(i);
            if (balance > 0) {
                addresses[i] = addr;
            }
        }

        return addresses;
    }

    function placeBet(uint256 investmentAmount, address better) public nonReentrant {
        require(better != address(0), "Invalid better address");
        require(investmentAmount > 0, "Investment amount must be > 0");

        // Wrap received tokens
        console.log("entered placebet, groupCRCToken", address(groupCRCToken));

        uint256 balanceBeforeWrap = ERC20(erc20Group).balanceOf(address(this));

        hub.wrap(address(groupCRCToken), investmentAmount, CirclesType.Inflation);
        console.log("erc20group inside placebet", address(erc20Group));
        // the balance will be greater than investmentAmount because demurrage not applied to inflationary tokens
        uint256 balanceAfterWrap = ERC20(erc20Group).balanceOf(address(this));

        console.log("balanceAfterWrap", balanceAfterWrap);
        uint256 amountToBet = balanceAfterWrap - balanceBeforeWrap;
        require(amountToBet > 0, "Wrap did not yield bettable tokens");

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

        // update balances
        updateBalance(better, expectedShares);
        //update supply
        _totalSupply += expectedShares;

        emit BetPlaced(better, investmentAmount, expectedShares);
    }

    function updateBalance(address better, uint256 expectedShares) internal {
        console.log("called UpdateBalance better", better);
        console.log("called UpdateBalance expectedShares", expectedShares);
        (bool exists, uint256 currentBalance) = _balances.tryGet(better);
        uint256 newBalance = exists ? currentBalance + expectedShares : expectedShares;
        _balances.set(better, newBalance);
    }

    function redeemAll(bytes32 conditionId, uint256[] memory indexSets) public {
        IConditionalTokens conditionalTokens = IConditionalTokens(address(fpmm.conditionalTokens()));
        // this will revert if market not resolved yet
        conditionalTokens.redeemPositions(IERC20(erc20Group), bytes32(0), conditionId, indexSets);

        buildClaimable();
    }

    function clearBalanceAndTotalSupply() internal {
        _totalSupply = 0;

        // Remove all elements one by one (see https://docs.openzeppelin.com/contracts/5.x/api/utils#EnumerableMap-clear-struct-EnumerableMap-AddressToBytes32Map-)
        uint256 length = _balances.length();
        console.log("balance length", length);
        for (uint256 i = 0; i < length; i++) {
            // Since we're removing elements, we always look at index 0
            (address key,) = _balances.at(0);
            _balances.remove(key);
        }
    }

    function buildClaimable() public nonReentrant {
        /**
         * Anyone can call this to calculate the shars of each user. This can (but need not be) called multiple times, once is sufficient to distribute earnings.
         */
        address[] memory addresses = getAddressesWithPositiveBalance();

        IERC20 erc20GroupToken = IERC20(erc20Group);
        uint256 totalCollateralToTransfer = erc20GroupToken.balanceOf(address(this));

        for (uint256 i = 0; i < addresses.length; i++) {
            address better = addresses[i];
            uint256 share = (balanceOf(better) * totalCollateralToTransfer) / _totalSupply;
            claimable[better] += share;
        }

        clearBalanceAndTotalSupply();
    }

    function claimMany(address[] calldata users) external nonReentrant {
        require(users.length > 0, "No users provided");

        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            require(user != address(0), "Invalid address");

            uint256 amount = claimable[user];
            if (amount > 0) {
                claimable[user] = 0;
                require(IERC20(erc20Group).transfer(user, amount), "Transfer failed");
            }
        }
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
