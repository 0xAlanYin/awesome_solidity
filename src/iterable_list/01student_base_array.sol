// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

// 创建一个"学校"智能合约来收集学生地址。合约必须具有3个主要要功能
// 1.在合约中添加或删除学生。
// 2.询问给定的学生地址是否属于学校。
// 3.获取所有学生的名单。
contract StudentBaseArray {
    address[] public students;

    constructor() {}

    // 添加学生
    function addStudent(address student) external {
        // check if student is already exist
        require(!isStudentBelongSchool(student), "add student already exist");

        // add student
        students.push(student);
    }

    // 删除学生
    function removeStudent(address student) external returns (bool) {
        // try get student index
        (, uint256 index) = _getStudentIndex(student);
        require(isStudentBelongSchool(student), "remove student not exist");

        // remove student
        students[index] = students[students.length - 1];
        students.pop();

        return true;
    }

    // 查询给定学生地址是否属于学校
    function isStudentBelongSchool(address student) public view returns (bool) {
        (bool exist,) = _getStudentIndex(student);
        return exist;
    }

    // 获取所有学生名单
    function getAllStudents() external view returns (address[] memory) {
        return students;
    }

    function _getStudentIndex(address student) internal view returns (bool, uint256) {
        for (uint256 i = 0; i < students.length; i++) {
            if (students[i] == student) {
                return (true, i);
            }
        }
        return (false, 0);
    }
}
