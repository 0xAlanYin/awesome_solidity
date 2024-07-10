// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// An example of a basic wallet.
// - Anyone can send ETH.
// - Only the owner can withdraw.
// https://solidity-by-example.org/app/ether-wallet/
contract EtherWallet {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {}

    function withdraw(uint256 amount) external {
        require(msg.sender == owner, "only owner can withdraw");
        owner.transfer(amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

// use openzeppelin
contract EtherWalletV2 is Ownable {
    constructor(address owner) Ownable(owner) {}

    receive() external payable {}

    function withdraw(uint256 amount) external onlyOwner {
        Address.sendValue(payable(msg.sender), amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
