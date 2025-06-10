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
        bytes32[] memory conditionIds
    ) public returns (address, address) {
        address collateralTokenAddress = IFixedProductMarketMaker(fpmmAddress).collateralToken();
        LiquidityRemover liquidityRemover = new LiquidityRemover(
            fpmmAddress,
            hubAddress,
            groupCRCToken,
            collateralTokenAddress,
            liquidityVaultTokenAddress,
            address(this),
            conditionIds
        );
        LiquidityAdder liquidityAdder = new LiquidityAdder(
            fpmmAddress,
            hubAddress,
            groupCRCToken,
            collateralTokenAddress,
            liquidityVaultTokenAddress,
            conditionIds.length
        );

        return (address(liquidityRemover), address(liquidityAdder));
    }
}
