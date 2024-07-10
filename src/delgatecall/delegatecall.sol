//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// code source: https://solidity-by-example.org/delegatecall/

// NOTE: Deploy this contract first
contract B {
    // NOTE: storage layout must be the same as contract A
    uint256 public number;
    address public sender;
    uint256 public value;

    function setValue(uint256 num) public payable {
        number = num;
        sender = msg.sender;
        value = msg.value;
    }
}

contract A {
    uint256 public number;
    address public sender;
    uint256 public value;

    function setValue(address payable addr, uint256 num) public payable {
        // A's storage is set, B is not modified.
        (bool success, bytes memory data) = addr.delegatecall(abi.encodeWithSignature("setValue(uint256)", num));
    }
}
