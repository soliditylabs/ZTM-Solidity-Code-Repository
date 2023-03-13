// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console2, StdStyle, StdCheats} from "forge-std/Test.sol";
import {ERC20} from "../contracts/ERC20.sol";

contract BaseSetup is ERC20, Test {
    address internal alice;
    address internal bob;

    constructor() ERC20("name", "SYM", 18) {}

    function setUp() public virtual {
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        console2.log(StdStyle.blue("When Alice has 300 Tokens"));
        deal(address(this), alice, 300e18);
    }
}

contract ERC20TransferTest is BaseSetup {
    function setUp() public override {
        BaseSetup.setUp();
    }

    function testTransfersTokenCorrectly() public {
        vm.prank(alice);
        bool success = this.transfer(bob, 100e18);
        assertTrue(success);

        assertEqDecimal(this.balanceOf(alice), 200e18, decimals);
        assertEqDecimal(this.balanceOf(bob), 100e18, decimals);
    }

    function testCannotTransferMoreThanBalance() public {
        vm.prank(alice);
        vm.expectRevert("ERC20: Insufficient sender balance");
        this.transfer(bob, 400e18);
    }

    function testEmitsTransferEvent() public {
        vm.expectEmit(true, true, true, true);
        emit Transfer(alice, bob, 100e18);

        vm.prank(alice);
        this.transfer(bob, 100e18);
    }
}

contract ERC20TransferFromTest is BaseSetup {}
