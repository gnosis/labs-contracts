// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "circles-contracts-v2/hub/Hub.sol";
import "circles-v2/lift/IERC20Lift.sol";

using EnumerableMap for EnumerableMap.AddressToUintMap;

/**
 * @title BettingUtils
 * @dev Utility functions for betting operations
 */
library BettingUtils {
    /**
     * @dev Calculates the amount to bet by wrapping tokens and measuring the difference
     * @param hub The Circles Hub contract
     * @param erc20Token The ERC20 token to check balance of
     * @param groupCRCToken The CRC token address to wrap
     * @param investmentAmount The amount of tokens to invest
     * @return amountToBet The calculated amount available for betting
     */
    /**
     * @dev Updates the balance of a better in the balances mapping
     * @param balances The mapping of addresses to their balances
     * @param better The address of the better
     * @param expectedShares The number of shares to add to the better's balance
     */
    function updateBalance(EnumerableMap.AddressToUintMap storage balances, address better, uint256 expectedShares)
        internal
    {
        (bool exists, uint256 currentBalance) = balances.tryGet(better);
        uint256 newBalance = exists ? currentBalance + expectedShares : expectedShares;
        balances.set(better, newBalance);
    }

    function defineAmountToBet(
        Hub hub,
        address erc20Token,
        address groupCRCToken,
        uint256 investmentAmount,
        CirclesType circlesType
    ) external returns (uint256) {
        uint256 balanceBeforeWrap = IERC20(erc20Token).balanceOf(address(this));

        hub.wrap(groupCRCToken, investmentAmount, circlesType);

        // the balance will be greater than investmentAmount because demurrage not applied to inflationary tokens
        uint256 balanceAfterWrap = IERC20(erc20Token).balanceOf(address(this));

        uint256 amountToBet = balanceAfterWrap - balanceBeforeWrap;
        require(amountToBet > 0, "Wrap did not yield bettable tokens");
        return amountToBet;
    }
}
