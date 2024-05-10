// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

// 需要根据分数来维持学生的排序,功能需求如下:
// 1.将新学生添加到具有分数排序的列表中
// 2.提高学生分数
// 3.降低学生分数
// 4.从名单中删除学生
// 5.获取前K名学生名单
contract StudentAdvance {
    // 学生的成绩
    mapping(address => uint256) private _studentScores;

    // 学生
    mapping(address => address) private _nextStudents;

    // 学生计数
    uint256 public size;

    // 哨兵
    address private constant GUARD = address(0);

    constructor() {
        _nextStudents[GUARD] = GUARD;
    }

    // 将新学生添加到具有分数排序的列表中
    /// @param student 新学生
    /// @param score  新学生成绩
    /// @param preStudent 待添加学生的前一个学生
    function addStudent(address student, uint256 score, address preStudent) external {
        _insertStudent(student, score, preStudent);
    }

    // 提高学生分数
    function increaseScore(address student, uint256 addScore, address oldPreStudent, address newPreStudent) external {
        uint256 newScore = _studentScores[student] + addScore;
        _updateScore(student, newScore, oldPreStudent, newPreStudent);
    }

    // 降低学生分数
    function reduceScore(address student, uint256 reduScore, address oldPreStudent, address newPreStudent) external {
        uint256 newScore = _studentScores[student] - reduScore;
        _updateScore(student, newScore, oldPreStudent, newPreStudent);
    }

    // 从名单中删除学生
    function removeStudent(address student, address preStudent) public {
        // 学生必须存在
        require(_isStudentExist(student), "student not exist");

        // 前置学生必须存在
        require(_isStudentExist(preStudent), "student not exist");

        // 检查前置学生确实是学生的前置节点
        require(_isPreStudent(preStudent, student), "this student is not pre of student");

        // 移除学生
        _nextStudents[preStudent] = _nextStudents[student];
        _nextStudents[student] = address(0);

        // 分数清空
        _studentScores[student] = 0;

        // 计数-1
        size--;
    }

    // 获取前K名学生名单
    function getTopKStudents(uint256 k) public view returns (address[] memory) {
        // k 大于 0
        require(k > 0, "k must be greater than 0");

        // k 小于等于 size
        require(k <= size, "k must be less than or equal to size");

        // 迭代学生列表
        address[] memory result = new address[](k);
        address current = _nextStudents[GUARD];
        for (uint256 i = 0; i < k; i++) {
            result[i] = current;
            current = _nextStudents[current];
        }
        return result;
    }

    function _updateScore(address student, uint256 newScore, address oldPreStudent, address newPreStudent) internal {
        // 学生必须存在
        require(_isStudentExist(student), "student not exist");

        // 旧前置学生必须存在
        require(_isStudentExist(oldPreStudent), "student not exist");

        // 新前置学生必须存在
        require(_isStudentExist(newPreStudent), "student not exist");

        if (oldPreStudent == newPreStudent) {
            // 如果旧前置学生和新前置相同
            // - 先检查旧前置学生确实是学生的前置节点
            require(_isPreStudent(oldPreStudent, student), "this student is not pre of student");
            // - 更新学生分数
            _studentScores[student] = newScore;
        } else {
            // 如果旧前置学生和新前置不同
            // - 移除学生节点
            removeStudent(student, oldPreStudent);
            // - 插入学生新节点
            _insertStudent(student, newScore, newPreStudent);
        }
    }

    function _insertStudent(address student, uint256 score, address preStudent) internal {
        // 新学生不存在
        require(!_isStudentExist(student), "student already exist");

        // 前置学生存在
        require(_isStudentExist(preStudent), "preStudent not exist");

        // 检查新学生成绩满足插入有序的条件: 分数小于等于前置学生，大于等于后置学生
        require(_verifyScore(preStudent, score, _nextStudents[preStudent]), "score not satisfy");

        // 添加学生
        _nextStudents[student] = _nextStudents[preStudent];
        _nextStudents[preStudent] = student;

        // 添加学生成绩
        _studentScores[student] = score;

        // 计数+1
        size++;
    }

    // 检查新学生成绩满足插入有序的条件: 分数小于等于前置学生，大于等于后置学生
    // 注意判断哨兵节点的特殊情况
    function _verifyScore(address preStudent, uint256 newScore, address nextStudent) private view returns (bool) {
        return (preStudent == GUARD || _studentScores[preStudent] >= newScore)
            && (nextStudent == GUARD || _studentScores[nextStudent] <= newScore);
    }

    function _isStudentExist(address student) internal view returns (bool) {
        return _nextStudents[student] != address(0);
    }

    // 是否为前置学生
    function _isPreStudent(address preStudent, address currentStudent) internal view returns (bool) {
        return _nextStudents[preStudent] == currentStudent;
    }
}
