//SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "../foundry_test/Wallet.sol";

contract TempContract {
    address a;

    address payable b;

    uint256[] arr;

    function name(uint256[] calldata addr3) public {
        State.START;
        type(uint256).max;

        payable(a).transfer(1900); //2300 gas
        b.transfer(10 ether); // 2300 gas
        bool ok = b.send(10); // 2300 gas

        b.call{value: 10}("");

        uint256 balance = a.balance;

        (bool ok2, bytes memory result) = a.call(abi.encodeWithSignature("add(uint256,uint256)", 1, 2));

        a.call(abi.encodeWithSelector(Wallet.withdraw.selector, 100));

        uint256[] storage addr1 = arr; // pointer
        uint256[] memory addr2 = arr; // copy storage to memory
        uint256[] calldata addr4 = addr3;

        arr.length;
        arr.push(1);
        arr.pop();

        abi.decode("", (uint256, string));

        address(this).balance;

        payable(a).transfer(100);

        a.call{value: 10}("");

        b.transfer(10); // 2300 gas
    }

    function name() public virtual {
        bytes4 functionName = bytes4(abi.encodeWithSignature("", 1, 2));

        bytes4 s = bytes4(keccak256("count(unint256,uint256)"));

        require(1 == 2, "error");
    }

    // 编码并存储数据
    bytes public encodedData;

    // 编码数据的函数
    function encodeData(uint256 number, address account, string memory message) public {
        encodedData = abi.encode(number, account, message);
    }

    // 解码数据的函数
    function decodeData() public view returns (uint256, address, string memory) {
        (uint256 number, address account, string memory message) = abi.decode(encodedData, (uint256, address, string));
        return (number, account, message);
    }

    receive() external payable {}

    fallback() external payable {}

    enum State {
        START,
        END
    }
}

interface Name {
    
}
