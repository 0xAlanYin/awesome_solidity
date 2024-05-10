// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Test.sol";

contract ConsoleTest is Test {

    function testConsole() view public {
        console.log("this is :", 1234);

        int x =2;
        console.logInt(x);
    }
}