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

    uint256 public immutable outcomeIndex;
    Hub public hub;
    address public groupCRCToken;
    address public erc20Group;

    // outcome token balances
    EnumerableMap.AddressToUintMap private _balances;
    uint256 private _totalSupply;
    // organization ID for Circles registration
    uint256 betContractIdentifier;

    mapping(address => uint256) public claimable;

    constructor(
        address fpmmAddress,
        address _groupCRCToken,
        uint256 _outcomeIndex,
        address _hubAddress,
        uint256 _betContractIdentifier
    ) {
        console.log("inside BetContract constructor");
        require(fpmmAddress != address(0), "Invalid FPMM address");
        require(_groupCRCToken != address(0), "Invalid group CRC token address");
        require(_hubAddress != address(0), "Invalid hub address");
        console.log("1");

        fpmm = IFixedProductMarketMaker(fpmmAddress);
        groupCRCToken = _groupCRCToken;
        outcomeIndex = _outcomeIndex;
        hub = Hub(_hubAddress);
        betContractIdentifier = _betContractIdentifier;
        console.log("2");

        erc20Group = hub.wrap(address(groupCRCToken), 0, CirclesType.Inflation);
        console.log("3");

        string memory orgaName = createCirclesOrganizationId();
        console.log("4", orgaName);
        bytes memory nameBytes = bytes(orgaName);
        console.log("name bytes", nameBytes.length);
        //if (nameBytes.length > 32 || nameBytes.length == 0) return false; // Check length
        hub.registerOrganization(orgaName, bytes32(0));
        // This assures that this contract always receives group CRC tokens.
        console.log("before hub trust");
        hub.trust(_groupCRCToken, type(uint96).max);
        console.log("end BetContract constructor");
    }

    function createCirclesOrganizationId() internal view returns (string memory) {
        string memory organizationId = string.concat(
            "Bet contract #", Strings.toString(betContractIdentifier), " - outcome ", Strings.toString(outcomeIndex)
        );
        console.log("organizationId", organizationId);
        return organizationId;
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

        uint256 balanceBeforeWrap = ERC20(erc20Group).balanceOf(address(this));

        hub.wrap(address(groupCRCToken), investmentAmount, CirclesType.Inflation);

        // the balance will be greater than investmentAmount because demurrage not applied to inflationary tokens
        uint256 balanceAfterWrap = ERC20(erc20Group).balanceOf(address(this));

        uint256 amountToBet = balanceAfterWrap - balanceBeforeWrap;
        require(amountToBet > 0, "Wrap did not yield bettable tokens");

        // authorize groupCRC

        uint256 allowance = ERC20(erc20Group).allowance(address(this), address(fpmm));

        if (allowance < amountToBet) {
            ERC20(erc20Group).approve(address(fpmm), amountToBet);
        }

        uint256 expectedShares = fpmm.calcBuyAmount(amountToBet, outcomeIndex);

        // 1% slippage
        uint256 balance = ERC20(fpmm.collateralToken()).balanceOf(address(this));

        fpmm.buy(amountToBet, outcomeIndex, expectedShares * 99 / 100);

        // update balances
        updateBalance(better, expectedShares);
        //update supply
        _totalSupply += expectedShares;

        emit BetPlaced(better, investmentAmount, expectedShares);
    }

    function updateBalance(address better, uint256 expectedShares) internal {
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
        // We only place bet if we received groupCRC tokens
        if (groupCRCToken == address(uint160(id))) {
            placeBet(value, from);
        }

        return super.onERC1155Received(operator, from, id, value, data);
    }
}
