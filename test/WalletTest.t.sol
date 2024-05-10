// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Test.sol";
import {Wallet} from "../src/foundry_test/Wallet.sol";

contract WalletTest is Test {
   
   Wallet public wallet;

   function setUp() public {
       wallet = new Wallet();
   }

    // test setOwner
    function testSetOwner() public {
        wallet.setOwner(address(1));
        assertEq(address(1), wallet.owner());
    }

    function testFail_NotOwner() public {
        // msg.sender == address(this)
        wallet.setOwner(address(1));

        vm.startPrank(address(1));
        wallet.setOwner(address(1));
        vm.stopPrank();
        
        vm.startPrank(address(2));
        wallet.setOwner(address(3));
        vm.stopPrank();
    }
}