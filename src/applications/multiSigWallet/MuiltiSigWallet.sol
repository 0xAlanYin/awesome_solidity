// SPDX-License-Identifier: MIT

pragma solidity >=0.8.24;

// The wallet owners can
// - submit a transaction
// - approve and revoke approval of pending transactions
// - anyone can execute a transaction after enough owners has approved it.
// source: https://solidity-by-example.org/app/multi-sig-wallet/
contract MultiSigWallet {
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event TransactionSummited(
        address indexed sender, uint256 indexed txIndex, address indexed to, uint256 value, bytes data
    );
    event TransactionConfirmed(address indexed sender, uint256 indexed txIndex);
    event TransacationExcuted(address indexed sender, uint256 indexed txIndex);
    event ConfirmationRevoked(address indexed sender, uint256 indexed txIndex);

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;

    // mapping from tx index => owner => isComfired
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "tx not exist");
        _;
    }

    modifier notExecute(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "tx already execute");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    constructor(address[] memory owners_, uint256 numConfirmationsRequired_) {
        // check params
        require(owners_.length > 0, "owner required");
        require(
            numConfirmationsRequired_ > 0 && numConfirmationsRequired_ <= owners_.length,
            "invalid number of required confirmations"
        );

        for (uint256 i = 0; i < owners_.length; i++) {
            address owner = owners_[i];

            // check owner not 0,not duplicate
            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "owner not unique");

            // add isOwner，owners
            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = numConfirmationsRequired_;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransacation(address _to, uint256 _value, bytes memory _data) public onlyOwner {
        uint256 txIndex = transactions.length;
        transactions.push(Transaction({to: _to, value: _value, data: _data, executed: false, numConfirmations: 0}));

        emit TransactionSummited(msg.sender, txIndex, _to, _value, _data);
    }

    function confirmTransacation(uint256 _txIndex, bool _isConfirm)
        public
        onlyOwner
        txExists(_txIndex)
        notExecute(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit TransactionConfirmed(msg.sender, _txIndex);
    }

    function excuteTransacation(uint256 _txIndex) public onlyOwner txExists(_txIndex) notExecute(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(transaction.numConfirmations >= numConfirmationsRequired, "cannot execute tx");

        transaction.executed = true;

        (bool ok,) = transaction.to.call{value: transaction.value}(transaction.data);
        require(ok, "transaction exectute failed");

        emit TransacationExcuted(msg.sender, _txIndex);
    }

    function revokeConfirmation(uint256 _txIndex) public onlyOwner txExists(_txIndex) notExecute(_txIndex) {
        address sender = msg.sender; // saving gas
        require(isConfirmed[_txIndex][sender], "tx not confirmed");

        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations -= 1;

        isConfirmed[_txIndex][sender] = false;

        emit ConfirmationRevoked(sender, _txIndex);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    function getTransactions(uint256 _txIndex)
        public
        view
        returns (address to, uint256 value, bytes memory data, bool executed, uint256 numConfirmations)
    {
        Transaction memory transaction = transactions[_txIndex];

        return (transaction.to, transaction.value, transaction.data, transaction.executed, transaction.numConfirmations);
    }
}

// Here is a contract to test sending transactions from the multi-sig wallet
contract TestContract {
    uint256 public i;

    function callMe(uint256 j) public {
        i += j;
    }

    function getData() public pure returns (bytes memory) {
        return abi.encodeWithSignature("callMe(uint256)", 112);
    }
}
