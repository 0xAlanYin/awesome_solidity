//SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface MyInterface {
    function myFunction() external;
}

contract MyContract is ERC165, MyInterface {
    constructor() {}

    function myFunction() external {
        // do something
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
    }
}

contract InterfaceChecker {
    constructor() {}

    function checkIntertface(address contractAddress) public view returns (bool) {
        IERC165 checker = IERC165(contractAddress);
        return checker.supportsInterface(type(MyInterface).interfaceId);
    }
}
