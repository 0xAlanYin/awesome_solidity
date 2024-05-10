// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

// 创建一个"学校"智能合约来收集学生地址。合约必须具有3个主要要功能:
// 1.在合约中添加或删除学生。
// 2.询问给定的学生地址是否属于学校。
// 3.获取所有学生的名单。
contract StudentMappingList {
    // 通过 mapping 实现一个可迭代的列表, 每一个 key 都是一个学生地址，value 是下一个学生地址
    mapping(address => address) private _nextStudents;

    // 哨兵
    address private constant GUARD = address(0);

    // 学生数量
    uint256 public size;

    constructor() {
        // 初始化哨兵
        _nextStudents[GUARD] = GUARD;
    }

    // 添加学生
    function addStudent(address student) external {
        // check if student is already exist
        require(!isStudentBelongSchool(student), "add student already exist");

        // add student
        _nextStudents[student] = _nextStudents[GUARD];
        _nextStudents[GUARD] = student;

        // size ++
        size++;
    }

    // 删除学生
    function removeStudent(address student) external {
        // check if student is already exist
        require(isStudentBelongSchool(student), "remove student not exist");

        // 获取前置节点
        address preStudent = _getPreStudent(student);
        // 删除节点
        _nextStudents[preStudent] = _nextStudents[student];
        _nextStudents[student] = address(0);

        // size--
        size--;
    }

    function removeStudentV2(address removeStudent, address preStudent) external {
        // check if student is already exist
        require(isStudentBelongSchool(removeStudent), "remove student not exist");

        // 删除节点
        _nextStudents[preStudent] = _nextStudents[removeStudent];
        _nextStudents[removeStudent] = address(0);

        // size--
        size--;
    }

    // 查询给定学生地址是否属于学校
    function isStudentBelongSchool(address student) public view returns (bool) {
        return _nextStudents[student] != address(0);
    }

    // 获取所有学生名单
    function getAllStudents() external view returns (address[] memory) {}

    function _getPreStudent(address student) internal view returns (address) {
        address currentStudent = GUARD;
        while (_nextStudents[currentStudent] != GUARD) {
            if (_nextStudents[currentStudent] == student) {
                return currentStudent;
            }
            currentStudent = _nextStudents[currentStudent];
        }
        // 找不到返回 0 地址
        return address(0);
    }
}
