pragma solidity ^0.8.0;

interface IFixedProductMarketMaker {
    // View functions
    function collectedFees() external view returns (uint256);
    function feesWithdrawableBy(address account) external view returns (uint256);
    function calcBuyAmount(uint256 investmentAmount, uint256 outcomeIndex) external view returns (uint256);
    function calcSellAmount(uint256 returnAmount, uint256 outcomeIndex) external view returns (uint256);
    function collateralToken() external view returns (address);

    // External state-changing functions
    function withdrawFees(address account) external;
    function addFunding(uint256 addedFunds, uint256[] calldata distributionHint) external;
    function removeFunding(uint256 sharesToBurn) external;
    function buy(uint256 investmentAmount, uint256 outcomeIndex, uint256 minOutcomeTokensToBuy) external;
    function sell(uint256 returnAmount, uint256 outcomeIndex, uint256 maxOutcomeTokensToSell) external;

    // ERC-1155 Receiver functions (for completeness if used externally)
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data)
        external
        returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}
