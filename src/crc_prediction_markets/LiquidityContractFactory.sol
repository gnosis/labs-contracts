// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LiquidityRemover.sol";
import "./LiquidityAdder.sol";
import "./IFixedProductMarketMaker.sol";
import "./LiquidityVaultToken.sol";

contract LiquidityContractFactory {
    function createLiquidityContracts(
        address hubAddress,
        address liquidityVaultTokenAddress,
        address groupCRCToken,
        address fpmmAddress,
        address betContractFactory,
        bytes32[] memory conditionIds,
        string[] memory liquidityOrganizationNames,
        bytes32[] memory liquidityOrganizationMetadataDigests
    ) public returns (address, address) {
        address collateralTokenAddress = address(IFixedProductMarketMaker(fpmmAddress).collateralToken());

        LiquidityAdder liquidityAdder = new LiquidityAdder(
            fpmmAddress,
            hubAddress,
            collateralTokenAddress,
            groupCRCToken,
            liquidityVaultTokenAddress,
            conditionIds.length,
            liquidityOrganizationNames[0],
            liquidityOrganizationMetadataDigests[0]
        );

        LiquidityRemover liquidityRemover = new LiquidityRemover(
            fpmmAddress,
            hubAddress,
            groupCRCToken,
            collateralTokenAddress,
            liquidityVaultTokenAddress,
            betContractFactory,
            conditionIds,
            liquidityOrganizationNames[1],
            liquidityOrganizationMetadataDigests[1]
        );

        return (address(liquidityRemover), address(liquidityAdder));
    }
}
