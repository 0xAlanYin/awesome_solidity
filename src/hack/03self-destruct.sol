//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts can be deleted from the blockchain by calling selfdestruct.
// selfdestruct sends all remaining Ether stored in the contract to a designated address.

// Vulnerability
// A malicious contract can use selfdestruct to force sending Ether to any contract.

// The goal of this game is to be the 7th player to deposit 1 Ether.
// Players can deposit only 1 Ether at a time.
// Winner will be able to withdraw all Ether.

/*
1. Deploy EtherGame
2. Players (say Alice and Bob) decides to play, deposits 1 Ether each.
2. Deploy Attack with address of EtherGame
3. Call Attack.attack sending 5 ether. This will break the game
   No one can become the winner.

What happened?
Attack forced the balance of EtherGame to equal 7 ether.
Now no one can deposit and the winner cannot be set.
*/

contract EtherGame {
    uint256 public constant TARGETAMOUNT = 7 ether;
    address public winner;

    constructor() {}

    function deposit() external payable {
        require(msg.value == 1 ether, "you can only send 1 ether");

        uint256 balance = address(this).balance;
        require(balance <= TARGETAMOUNT, "Game is over");

        if (balance == TARGETAMOUNT) {
            winner = msg.sender;
        }
    }
}
