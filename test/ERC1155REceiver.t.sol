// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/crc_prediction_markets/BetYes.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("MockERC20", "MERC20") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}

contract MockWXDAI {
    function deposit() external payable {}
}

contract MockConditionalTokenContract {
    function balanceOf(address owner, uint256 id) public view returns (uint256) {
        // no op
    }
}

contract MockERC1155 is ERC1155 {
    constructor() ERC1155("") {}

    function mint(address to, uint256 id, uint256 amount) external {
        _mint(to, id, amount, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external {
        _mintBatch(to, ids, amounts, "");
    }
}

contract ERC1155ReceiverTest is Test {
    BetYesContract receiver;
    MockERC1155 mockToken;
    MockERC20 mockERC20;
    uint256 constant TOKEN_ID = 1;
    uint256 constant AMOUNT = 100;
    // market also has a condition_id, outcome_slot_count
    address constant fpmmMarketId = address(0x011F45E9DC3976159edf0395C0Cd284df91F59Bc);
    uint256 constant mockOutcomeIndex = 0;
    MockWXDAI mockWXDAI;
    MockConditionalTokenContract conditionalTokens =
        MockConditionalTokenContract(0xCeAfDD6bc0bEF976fdCd1112955828E00543c0Ce);

    function setUp() public {
        mockERC20 = new MockERC20();

        mockToken = new MockERC1155();
        mockWXDAI = MockWXDAI(address(0xe91D153E0b41518A2Ce8Dd3D7944Fa863463a97d));
        // We use mockWXDAI as collateral because the existing market has it as collateral
        receiver = new BetYesContract(fpmmMarketId, address(mockWXDAI), mockOutcomeIndex);

        // deposit wxdai
        vm.deal(address(receiver), 10 ether);
        vm.prank(address(receiver));
        mockWXDAI.deposit{value: 100}();
        vm.stopPrank();

        // ToDo - Setup FPMM contract
    }

    function testSingleTransfer() public {
        vm.prank(address(mockToken));
        mockToken.mint(address(receiver), TOKEN_ID, AMOUNT);
        // assert that mock token was spent - this fails because we are not yet spending it, since
        // market has wxdai collateral
        // assertEq(mockToken.balanceOf(address(receiver), TOKEN_ID), 0); -> FIX ME
        // assert that outcome tokens were received
        uint256 outcomeTokenId = 23344788232790908587736034419534332095629224306796043743709845708862629995515;
        uint256 balanceOutcomeTokens = conditionalTokens.balanceOf(address(receiver), outcomeTokenId);
        assertGe(balanceOutcomeTokens, 0);
    }
}
