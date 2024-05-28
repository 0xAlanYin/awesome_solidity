//SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract Pair {
    // 函数选择器的常量写法例子
    bytes4 constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
}
