//SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract TestIsContract {
    function onlyEOACanCall() external {
        require(!isContract(msg.sender), "contract not allowed");
        // do something
    }

    // 判断一个地址是否为合约地址
    function isContract(address account) public view returns (bool) {
        uint256 size;
        // 通过内联汇编调用 extcodesize 操作码
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function isContractV2(address account) public view returns (bool) {
        return account.code.length > 0;
    }
}
