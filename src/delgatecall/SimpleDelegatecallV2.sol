// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// NOTE: Deploy this contract first
contract B {
    // NOTE: storage layout must be the same as contract A
    uint256 public num;
    address public sender;
    uint256 public value;

    function setVars(uint256 _num) public payable {
        num = _num;
        sender = msg.sender;
        value = msg.value;
    }
}

// 演示:更改变量名不影响 delegatecall,因为底层实现是基于 slot 槽做的

contract A {
    uint256 public firstValue;
    address public secondValue;
    uint256 public thirdValue;

    function setVars(address _contract, uint256 _num) public payable {
        // A's storage is set, B is not modified.
        (bool success, bytes memory data) = _contract.delegatecall(abi.encodeWithSignature("setVars(uint256)", _num));
    }

    // 即使更改变量名也没有关系，底层的机制类似于下面（仅演示原理，方便理解）
    // function setVars(uint256 _num) public payable {
    //     // storageSlot[0] = _num; // 底层是通过slot槽的位置来赋值，而不是看变量名
    //     firstValue = _num;
    //     secondValue = msg.sender;
    //     thirdValue = msg.value;
    // }
}
