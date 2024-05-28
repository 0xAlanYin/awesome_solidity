//SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract C {
    uint256 public data;

    function f(uint256 a) private pure returns (uint256 b) {
        return a + 1;
    }

    function setData(uint256 a) external {
        data = a;
    }
}

contract CreateContract {
    function createContract1() public returns (address) {
        C c = new C();
        return address(c);
    }

    function createContract2(address impl) public returns (address) {
        return createClone(impl);
    }

    // create2 的方式创建
    function createContract3(uint256 _salt) public returns (address) {
        C c = new C{salt: keccak256(abi.encode(_salt))}();
        return address(c);
    }

    function getCreate2Address(uint256 _salt) public view returns (address) {
        bytes memory bytecode = type(C).creationCode;

        bytes32 hash =
            keccak256(abi.encodePacked(bytes1(0xff), address(this), keccak256(abi.encode(_salt)), keccak256(bytecode)));

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    function createClone(address prototype) internal returns (address proxy) {
        bytes20 targetBytes = bytes20(prototype);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            proxy := create(0, clone, 0x37)
        }
        return proxy;
    }
}
