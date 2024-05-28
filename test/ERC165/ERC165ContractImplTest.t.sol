// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Test.sol";

import {MyInterface, MyContract, InterfaceChecker} from "../../src/ERC165/ERC165ContractImpl.sol";

contract InterfaceCheckerTest is Test {
    InterfaceChecker checker;

    MyContract myContract;

    function setUp() public {
        myContract = new MyContract();

        checker = new InterfaceChecker();
    }

    // test checkIntertface
    function testCheckIntertface() public {
        assertTrue(checker.checkIntertface(address(myContract)));
    }
}
