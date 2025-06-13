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
abstract contract BettingUtils {
    function defineAmountToBet(
        address hubAddress,
        address erc20Token,
        address groupCRCToken,
        uint256 investmentAmount,
        CirclesType circlesType
    ) internal returns (uint256) {
        uint256 balanceBeforeWrap = IERC20(erc20Token).balanceOf(address(this));

        Hub(hubAddress).wrap(groupCRCToken, investmentAmount, circlesType);

        // the balance will be greater than investmentAmount because demurrage not applied to inflationary tokens
        uint256 balanceAfterWrap = IERC20(erc20Token).balanceOf(address(this));

        uint256 amountToBet = balanceAfterWrap - balanceBeforeWrap;
        require(amountToBet > 0, "Wrap did not yield bettable tokens");
        return amountToBet;
    }
}
