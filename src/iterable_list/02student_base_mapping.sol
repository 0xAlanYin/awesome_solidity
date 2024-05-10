// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

// 创建一个"学校"智能合约来收集学生地址。合约必须具有3个主要要功能
// 1.在合约中添加或删除学生。
// 2.询问给定的学生地址是否属于学校。
// 3.获取所有学生的名单。
contract StudentBaseMapping {
    mapping(address => bool) public students;

    constructor() {}

    function addStudent(address student) external {
        // check if student is already exist
        bool exist = _isStudentExist(student);
        require(!exist, "StudentBaseMapping: add student already exist");

        // add student
        students[student] = true;
    }

    function removeStudent(address student) external {
        // check if student is already exist
        bool exist = _isStudentExist(student);
        require(exist, "StudentBaseMapping: remove student not exist");

        // remove student
        students[student] = false;
    }

    // 获取所有学生的名单:mapping结构不支持遍历，怎么解决？==> 使用 mapping 实现一个可迭代的列表


    function _isStudentExist(address student) internal view returns (bool) {
        return students[student];
    }
}
