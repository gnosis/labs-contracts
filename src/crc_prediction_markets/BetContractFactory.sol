// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BetContract.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./LiquidityRemover.sol";
import "./LiquidityAdder.sol";
import {console} from "forge-std/console.sol";

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
    // for holding LP shares of fixed product market makers
    LiquidityVaultToken public liquidityVaultToken;

    constructor(address _hubAddress) {
        hubAddress = _hubAddress;
        liquidityVaultToken = new LiquidityVaultToken();
    }

    event BetContractDeployed(address indexed betContract, uint256 indexed outcomeIndex);

    // Mapping from FPMM address to market information
    mapping(address => MarketInfo) public fpmmToBetContracts;

    EnumerableSet.AddressSet private fpmmAddresses;

    // Public function to return all processed FPMM addresses
    function getAllProcessedFPMMAddresses() external view returns (address[] memory) {
        return fpmmAddresses.values();
    }

    function getMarketInfo(address fpmmAddress) public view returns (MarketInfo memory) {
        return fpmmToBetContracts[fpmmAddress];
    }

    function fpmmAlreadyProcessed(address fpmmAddress) public view returns (bool) {
        return fpmmAddresses.contains(fpmmAddress);
    }

    function createBetContract(
        address fpmmAddress,
        address groupCRCToken,
        uint256 outcomeIndex,
        uint256 betContractIdentifier,
        string memory organizationName,
        bytes32 organizationMetadataDigest,
        address liquidityRemover
    ) private returns (address) {
        BetContract betContract = new BetContract(
            fpmmAddress,
            groupCRCToken,
            outcomeIndex,
            hubAddress,
            betContractIdentifier,
            organizationName,
            organizationMetadataDigest,
            address(liquidityRemover)
        );
        emit BetContractDeployed(address(betContract), outcomeIndex);

        return address(betContract);
    }

    function createBetContractsForFpmm(
        address fpmmAddress,
        address groupCRCToken,
        uint256[] memory outcomeIndexes,
        bytes32[] memory conditionIds,
        string[] memory organizationNames,
        bytes32[] memory organizationMetadataDigests
    ) external {
        console.log("entered createBetContractsForFpmm");
        require(fpmmAddress != address(0), "Invalid FPMM address");
        require(groupCRCToken != address(0), "Invalid group CRC token address");

        // Create market if it doesn't exist
        if (!fpmmAddresses.contains(fpmmAddress)) {
            console.log("1 Bet Contract Factory");
            uint256 betContractIdentifier = fpmmAddresses.length();
            console.log("2");
            LiquidityRemover liquidityRemover = new LiquidityRemover(
                fpmmAddress, hubAddress, groupCRCToken, address(liquidityVaultToken), address(this), conditionIds
            );
            console.log("3");
            LiquidityAdder liquidityAdder = new LiquidityAdder(
                fpmmAddress, hubAddress, groupCRCToken, address(liquidityVaultToken), conditionIds.length
            );
            console.log("4");
            address[] memory betContracts = new address[](outcomeIndexes.length);
            for (uint8 outcomeIdx = 0; outcomeIdx < outcomeIndexes.length; outcomeIdx++) {
                console.log("5");
                address betContractAddr = createBetContract(
                    fpmmAddress,
                    groupCRCToken,
                    outcomeIndexes[outcomeIdx],
                    betContractIdentifier,
                    organizationNames[outcomeIdx],
                    organizationMetadataDigests[outcomeIdx],
                    address(liquidityRemover)
                );
                betContracts[outcomeIdx] = betContractAddr;
            }
            console.log("6");
            fpmmToBetContracts[fpmmAddress] = MarketInfo({
                fpmmAddress: fpmmAddress,
                groupCRCToken: groupCRCToken,
                outcomeIdxs: outcomeIndexes,
                betContracts: betContracts
            });
            console.log("7");
            fpmmAddresses.add(fpmmAddress);
        }
    }
}
