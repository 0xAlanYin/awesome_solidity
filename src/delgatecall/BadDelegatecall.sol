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

contract A {
    // 演示副作用：将第一个元素改为 bool,调用 A 的 setVars 会得到奇怪的效果(底层实现是基于 slot 槽做的,结构定义不一样会造成意想不到的结果)
    bool public firstValue;
    address public secondValue;
    uint256 public thirdValue;

    function setVars(address _contract, uint256 _num) public payable {
        // A's storage is set, B is not modified.
        (bool success, bytes memory data) = _contract.delegatecall(abi.encodeWithSignature("setVars(uint256)", _num));
    }
}
