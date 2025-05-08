// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BetContract.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Struct to store market information
struct MarketInfo {
    address fpmmAddress;
    address groupCRCToken;
    uint8[] outcomeIdxs;
    address[] betContracts;
}

contract BetContractFactory {
    using EnumerableSet for EnumerableSet.AddressSet;

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
        console.log("inside createBetContract");
        BetContract betContract = new BetContract(fpmmAddress, groupCRCToken, outcomeIndex, hubAddress);
        emit BetContractDeployed(address(betContract), outcomeIndex);
        console.log("bet contract deployed");
        return address(betContract);
    }

    function createBetContractsForFpmm(
        address fpmmAddress,
        address groupCRCToken,
        uint256 outcomeIndex,
        address hubAddress
    ) external {
        // Create market if it doesn't exist
        if (!fpmmAddresses.contains(fpmmAddress)) {
            // We assume binary markets, hence 2 outcomes
            uint8[] memory outcomeIdxs = new uint8[](2);
            address[] memory betContracts = new address[](2);
            for (uint8 outcomeIdx = 0; outcomeIdx < 2; outcomeIdx++) {
                address betContractAddr = createBetContract(fpmmAddress, groupCRCToken, outcomeIdx, hubAddress);
                betContracts[outcomeIdx] = betContractAddr;
                outcomeIdxs[outcomeIdx] = outcomeIdx;
            }

            fpmmToBetContracts[fpmmAddress] = MarketInfo({
                fpmmAddress: fpmmAddress,
                groupCRCToken: groupCRCToken,
                outcomeIdxs: outcomeIdxs,
                betContracts: betContracts
            });

            fpmmAddresses.add(fpmmAddress);
        }
    }
}
