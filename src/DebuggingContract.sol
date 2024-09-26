// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.4.25;

/// @dev Simple debugging contract.
contract DebuggingContract {
    uint256 public counter;

    function getNow() public view returns (uint32) {
        return uint32(now);
    }

    function inc() public {
        if (counter == 2 ** 256 - 1) {
            counter = 0;
        } else {
            counter += 1;
        }
    }
}
