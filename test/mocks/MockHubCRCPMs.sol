// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "circles-v2/lift/IERC20Lift.sol";

contract MockHubCRCPMs {
    address public wrappedToken;

    function wrap(address token, uint256 amount, CirclesType _type) external returns (address) {
        require(token != address(0), "Invalid token address");

        // For testing purposes, we'll just return the same token address
        wrappedToken = token;
        return token;
    }

    function trust(address _trustReceiver, uint96 _expiry) external {
        // do nothing
    }

    function registerOrganization(string memory, /*orgaName*/ bytes32 /*identifier*/ ) external {
        // No-op for testing
    }
}
