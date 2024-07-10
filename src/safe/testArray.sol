//SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract TestArrayBad {
    error TestArrayBad_UserAlreadEntered(address user);

    address[] private s_enters;

    constructor() {}

    function enter() public {
        address user = msg.sender;
        for (uint256 i = 0; i < s_enters.length; i++) {
            if (s_enters[i] == user) {
                revert TestArrayBad_UserAlreadEntered(user);
            }
        }
        s_enters.push(user);
    }
}
