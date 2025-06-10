// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BetContract.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./LiquidityRemover.sol";
import "./LiquidityAdder.sol";

// Struct to store market information
struct MarketInfo {
    address fpmmAddress;
    address groupCRCToken;
    uint256[] outcomeIdxs;
    address[] betContracts;
}

struct LiquidityInfo {
    address liquidityVaultToken;
    address liquidityAdder;
    address liquidityRemover;
}

contract BetContractFactory is Pausable, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public hubAddress;
    // for holding LP shares of fixed product market makers
    LiquidityVaultToken public liquidityVaultToken;

    constructor(address _hubAddress) Ownable(msg.sender) {
        hubAddress = _hubAddress;
        liquidityVaultToken = new LiquidityVaultToken();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    event BetContractDeployed(address indexed betContract, uint256 indexed outcomeIndex);

    // Mapping from FPMM address to market information
    mapping(address => MarketInfo) public fpmmToBetContracts;
    mapping(address => LiquidityInfo) public fpmmToLiquidityInfo;

    EnumerableSet.AddressSet private fpmmAddresses;

    // Public function to return all processed FPMM addresses
    function getAllProcessedFPMMAddresses() external view returns (address[] memory) {
        return fpmmAddresses.values();
    }

    function getMarketInfo(address fpmmAddress) public view returns (MarketInfo memory) {
        return fpmmToBetContracts[fpmmAddress];
    }

    function getLiquidityInfo(address fpmmAddress) public view returns (LiquidityInfo memory) {
        return fpmmToLiquidityInfo[fpmmAddress];
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
    ) private whenNotPaused returns (address) {
        BetContract betContract = new BetContract(
            fpmmAddress,
            groupCRCToken,
            outcomeIndex,
            hubAddress,
            betContractIdentifier,
            organizationName,
            organizationMetadataDigest,
            liquidityRemover
        );
        emit BetContractDeployed(address(betContract), outcomeIndex);

        return address(betContract);
    }

    function createContractsForFpmm(
        address fpmmAddress,
        address groupCRCToken,
        uint256[] memory outcomeIndexes,
        bytes32[] memory conditionIds,
        string[] memory organizationNames,
        bytes32[] memory organizationMetadataDigests
    ) external whenNotPaused {
        require(fpmmAddress != address(0), "Invalid FPMM address");
        require(groupCRCToken != address(0), "Invalid group CRC token address");

        // Create market if it doesn't exist
        if (!fpmmAddresses.contains(fpmmAddress)) {
            (LiquidityRemover liquidityRemover, LiquidityAdder liquidityAdder) =
                createLiquidityContracts(fpmmAddress, groupCRCToken, conditionIds);

            address[] memory spenders = new address[](2);
            spenders[0] = address(liquidityAdder);
            spenders[1] = address(liquidityRemover);
            liquidityVaultToken.approveMarketMakerLPTokensSpend(fpmmAddress, spenders);

            address[] memory betContracts = new address[](outcomeIndexes.length);
            uint256 betContractIdentifier = fpmmAddresses.length();
            for (uint8 outcomeIdx = 0; outcomeIdx < outcomeIndexes.length; outcomeIdx++) {
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
            fpmmToBetContracts[fpmmAddress] = MarketInfo({
                fpmmAddress: fpmmAddress,
                groupCRCToken: groupCRCToken,
                outcomeIdxs: outcomeIndexes,
                betContracts: betContracts
            });
            fpmmToLiquidityInfo[fpmmAddress] = LiquidityInfo({
                liquidityAdder: address(liquidityAdder),
                liquidityRemover: address(liquidityRemover),
                liquidityVaultToken: address(liquidityVaultToken)
            });
            fpmmAddresses.add(fpmmAddress);
        }
    }

    function createLiquidityContracts(address fpmmAddress, address groupCRCToken, bytes32[] memory conditionIds)
        internal
        returns (LiquidityRemover, LiquidityAdder)
    {
        liquidityVaultToken.addUpdater(address(this), fpmmAddress);

        LiquidityRemover liquidityRemover = new LiquidityRemover(
            fpmmAddress, hubAddress, groupCRCToken, address(liquidityVaultToken), address(this), conditionIds
        );
        liquidityVaultToken.addUpdater(address(liquidityRemover), fpmmAddress);
        LiquidityAdder liquidityAdder = new LiquidityAdder(
            fpmmAddress, hubAddress, groupCRCToken, address(liquidityVaultToken), conditionIds.length
        );
        liquidityVaultToken.addUpdater(address(liquidityAdder), fpmmAddress);
        return (liquidityRemover, liquidityAdder);
    }
}
