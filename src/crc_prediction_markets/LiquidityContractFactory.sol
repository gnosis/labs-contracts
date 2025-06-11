// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LiquidityRemover.sol";
import "./LiquidityAdder.sol";
import "./IFixedProductMarketMaker.sol";
import "./LiquidityVaultToken.sol";
import {console} from "forge-std/console.sol";

contract LiquidityContractFactory {
    function createLiquidityContracts(
        address hubAddress,
        address liquidityVaultTokenAddress,
        address groupCRCToken,
        address fpmmAddress,
        address betContractFactory,
        bytes32[] memory conditionIds
    ) public returns (address, address) {
        console.log("entered createLiquidityContracts");
        address collateralTokenAddress = address(IFixedProductMarketMaker(fpmmAddress).collateralToken());
        console.log("createLiquidityContracts, after collateralToken()");

        LiquidityRemover liquidityRemover = new LiquidityRemover(
            fpmmAddress,
            hubAddress,
            groupCRCToken,
            collateralTokenAddress,
            liquidityVaultTokenAddress,
            betContractFactory,
            conditionIds
        );
        console.log("createLiquidityContracts, after LiquidityRemover");

        LiquidityAdder liquidityAdder = new LiquidityAdder(
            fpmmAddress,
            hubAddress,
            collateralTokenAddress,
            groupCRCToken,
            liquidityVaultTokenAddress,
            conditionIds.length
        );
        console.log("createLiquidityContracts, after LiquidityAdder");
        return (address(liquidityRemover), address(liquidityAdder));
    }
}
