//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// code source: https://solidity-by-example.org/call/
// Few reasons why low-level call is not recommended
// - Reverts are not bubbled up
// - Type checks are bypassed
// - Function existence checks are omitted

contract Receiver {
    event Received(address indexed caller, uint256 amount, string message);

    fallback() external payable {
        emit Received(msg.sender, msg.value, "Fallback was called");
    }

    function foo(string memory message, uint256 x) public payable returns (uint256) {
        emit Received(msg.sender, msg.value, message);

        return x + 1;
    }
}

contract Caller {
    event Response(bool success, bytes data);

    // imagine that contract Caller does not have the source code(for demo) for the
    // contract Receiver, but we do know the address of contract Receiver and the function to call.
    function testCallFoo(address payable addr) public payable {
        (bool ok, bytes memory data) =
            addr.call{value: msg.value, gas: 5000}(abi.encodeWithSignature("foo(string,uint256)", "call foo", 123));

        emit Response(ok, data);
    }

    function testCallNotExistFunction(address payable addr) public payable {
        (bool ok, bytes memory data) = addr.call{value: msg.value, gas: 5000}(abi.encodeWithSignature("notExist()"));

        emit Response(ok, data);
    }
}
