//SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract TestSelfdestructBad {
    uint256 public totalDeposits;
    mapping(address => uint256) public deposits;

    function deposit() external payable {
        uint256 amount = msg.value;
        deposits[msg.sender] += amount;
        totalDeposits += amount;
    }

    function withdraw() external {
        require(address(this).balance == totalDeposits);

        address user = msg.sender;
        uint256 amount = deposits[user];
        totalDeposits -= amount;
        payable(user).transfer(amount);
    }
}

// Attacker
contract Attacker {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    function attack(address payable target) external {
        require(owner == msg.sender, "only owner can operate");
        selfdestruct(target);
    }
}

contract TestSelfdestructGood {
    uint256 public totalDeposits;
    mapping(address => uint256) public deposits;

    function deposit() external payable {
        uint256 amount = msg.value;
        deposits[msg.sender] += amount;
        totalDeposits += amount;
    }

    function withdraw() external {
        // remove unneccessary check

        address user = msg.sender;
        uint256 amount = deposits[user];
        totalDeposits -= amount;
        // transfer has 2100 gas limit
        (bool ok,) = user.call{value: amount}("");
        require(ok);
    }
}
