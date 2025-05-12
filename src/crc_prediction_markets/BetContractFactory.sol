// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BetContract.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Struct to store market information
struct MarketInfo {
    address fpmmAddress;
    address groupCRCToken;
    uint256[] outcomeIdxs;
    address[] betContracts;
}

contract BetContractFactory {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public hubAddress;

    constructor(address _hubAddress) {
        hubAddress = _hubAddress;
    }

    event BetContractDeployed(address indexed betContract, uint256 indexed outcomeIndex);

    // Mapping from FPMM address to market information
    mapping(address => MarketInfo) public fpmmToBetContracts;

    EnumerableSet.AddressSet private fpmmAddresses;

    function getMarketInfo(address fpmmAddress) public view returns (MarketInfo memory) {
        return fpmmToBetContracts[fpmmAddress];
    }

    function fpmmAlreadyProcessed(address fpmmAddress) public view returns (bool) {
        return fpmmAddresses.contains(fpmmAddress);
    }

    function createBetContract(address fpmmAddress, address groupCRCToken, uint256 outcomeIndex, address hubAddress)
        private
        returns (address)
    {
        BetContract betContract = new BetContract(fpmmAddress, groupCRCToken, outcomeIndex, hubAddress);
        emit BetContractDeployed(address(betContract), outcomeIndex);

        return address(betContract);
    }

    function createBetContractsForFpmm(address fpmmAddress, address groupCRCToken, uint256[] memory outcomeIndexes)
        external
    {
        // Create market if it doesn't exist
        if (!fpmmAddresses.contains(fpmmAddress)) {
            // We assume binary markets, hence 2 outcomes

            address[] memory betContracts = new address[](outcomeIndexes.length);
            for (uint8 outcomeIdx = 0; outcomeIdx < outcomeIndexes.length; outcomeIdx++) {
                address betContractAddr =
                    createBetContract(fpmmAddress, groupCRCToken, outcomeIndexes[outcomeIdx], hubAddress);
                betContracts[outcomeIdx] = betContractAddr;
            }

            fpmmToBetContracts[fpmmAddress] = MarketInfo({
                fpmmAddress: fpmmAddress,
                groupCRCToken: groupCRCToken,
                outcomeIdxs: outcomeIndexes,
                betContracts: betContracts
            });

            fpmmAddresses.add(fpmmAddress);
        }
    }
}
