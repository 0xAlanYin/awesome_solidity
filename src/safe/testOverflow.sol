//SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract TestOverflow {
    uint256 public moneyToShare = 115;
    uint256 public shareUsersCount = 4;
    uint256 public count = 0;

    function shareMoney() external view returns (uint256) {
        return moneyToShare / shareUsersCount;
    }

    function decrement() external {
        unchecked {
            count--;
        }
    }
}
