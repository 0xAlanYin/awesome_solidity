//SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";

contract TestSignatureReuseBad is EIP712 {
    bytes32 private constant STRUCT_TYPE_HASH = keccak256("WithdrawBySignature(uint256 amount)");

    mapping(address => uint256) public deposits;

    constructor() EIP712("TestSignatureReuseBad", "1") {}

    function deposit() external payable {
        uint256 amount = msg.value;
        deposits[msg.sender] += amount;
    }

    function withdrawBySignature(uint256 amount, uint8 v, bytes32 r, bytes32 s) external payable {
        bytes32 structHash = _caculateStructHash(amount);
        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(digest, v, r, s);
        _withdraw(signer, amount);
    }

    function _caculateStructHash(uint256 amount) internal pure returns (bytes32) {
        return keccak256(abi.encode(STRUCT_TYPE_HASH, amount));
    }

    function _withdraw(address user, uint256 amount) private {
        uint256 currentBalance = deposits[user];
        require(currentBalance <= amount, "insufficent balance");
        deposits[user] -= amount;
        payable(msg.sender).transfer(amount);
    }
}

contract TestSignatureReuseGood is EIP712, Nonces {
    bytes32 private constant STRUCT_TYPE_HASH =
        keccak256("WithdrawBySignature(uint256 amount,uint256 nonce,uint256 deadline)");

    mapping(address => uint256) public deposits;

    constructor() EIP712("TestSignatureReuseBad", "1") {}

    function deposit() external payable {
        uint256 amount = msg.value;
        deposits[msg.sender] += amount;
    }

    function withdrawBySignature(address owner, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
        payable
    {
        bytes32 structHash = _caculateStructHash(amount, _useNonce(owner), deadline);
        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(digest, v, r, s);
        require(signer == owner, "invalid signer");
        _withdraw(signer, amount);
    }

    function _caculateStructHash(uint256 amount, uint256 nonce, uint256 deadline) internal pure returns (bytes32) {
        return keccak256(abi.encode(STRUCT_TYPE_HASH, amount, nonce, deadline));
    }

    function _withdraw(address user, uint256 amount) private {
        uint256 currentBalance = deposits[user];
        require(currentBalance <= amount, "insufficent balance");
        deposits[user] -= amount;
        (bool ok,) = msg.sender.call{value: amount}("");
        require(ok, "withdraw failed");
    }
}
