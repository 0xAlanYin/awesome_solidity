// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// 逻辑合约/实现合约 Implementation
/**
 * @dev 逻辑合约，执行被委托的调用
 */
contract LogicV1 {
    // 与Proxy保持一致，防止插槽冲突
    address public implementation;
    uint256 public x = 99;

    // 调用成功事件
    event CallSuccess();

    // 这个函数会释放CallSuccess事件并返回一个uint。
    // 函数selector: 0xd09de08a
    function increment() external returns (uint256) {
        emit CallSuccess();
        return x + 1;
    }
}

contract LogicV2 {
    address public implementation;
    // 变更
    uint256 public x = 66;

    event CallSuccess();

    function increment() external returns (uint256) {
        emit CallSuccess();
        // 变更
        return x + 10;
    }
}

// ---------------------------------------------------------------------------------------------------------

// 代理合约（Proxy）
contract SimpleProxy {
    // 逻辑合约地址。implementation合约同一个位置的状态变量类型必须和Proxy合约的相同，不然会报错。
    address public implementation;

    /**
     * @dev 初始化逻辑合约地址
     */
    constructor(address implementation_) {
        implementation = implementation_;
    }

    fallback() external payable {
        _delegate();
    }

    /**
     * @dev 将调用委托给逻辑合约运行
     */
    function _delegate() internal {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // 读取位置为0的storage，也就是implementation地址。
            let _implementation := sload(0)

            // calldatacopy(t, f, s)：将calldata（输入数据）从位置f开始复制s字节到mem（内存）的位置t
            calldatacopy(0, 0, calldatasize())

            // 利用delegatecall调用implementation合约
            // delegatecall操作码的参数分别为：gas, 目标合约地址，input mem起始位置，input mem长度，output area mem起始位置，
            // output area mem长度，output area起始位置和长度位置，所以设为0
            // delegatecall成功返回1，失败返回0
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

            // returndatacopy(t, f, s)：将returndata（输出数据）从位置f开始复制s字节到mem（内存）的位置t。
            // 将起始位置为0，长度为returndatasize()的returndata复制到mem位置0
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                // revert(p, s)：终止函数执行, 回滚状态，返回数据mem[p..(p+s))
                // 如果delegate call失败，revert
                revert(0, returndatasize())
            }
            default {
                // return(p, s)：终止函数执行, 返回数据mem[p..(p+s))
                // 如果delegate call成功，返回mem起始位置为0，长度为returndatasize()的数据（格式为bytes）
                return(0, returndatasize())
            }
        }
    }
}

// ---------------------------------------------------------------------------------------------------------

// 调用者合约
contract Caller {
    address public proxy;

    constructor(address proxy_) {
        proxy = proxy_;
    }

    function increament() external returns (uint256) {
        (bool success, bytes memory result) = proxy.call(abi.encodeWithSignature("increment()"));
        if (success) {
            return abi.decode(result, (uint256));
        }
        revert();
    }
}
