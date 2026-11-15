// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


contract MultiSigWallet{
    event Deposit(address indexed sender, uint amount);
    event Submit( uint indexed txId);
    event Approve(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);


    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner!");
        _;
    }

    modifier notApproved(uint256 _txId) {
        require(!Approved[_txId][msg.sender], "already approved");
        _;
    }

    modifier exists(uint256 _txId) {
        require(_txId < transactions.length, "invalid txId");
        _;
    }

    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "already executed");
        _;
    }

    //交易结构体数组
    struct transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }


    //状态变量
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public required;
    mapping(uint256 => mapping(address => bool)) public Approved;
    transaction[] public transactions;

    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0,"owner require");
        require(_required > 0 && _required <= _owners.length,"invalid _require");

        for(uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "invalid owner address");
            require(!isOwner[owner], "already added the owner");

            isOwner[owner] = true;
            owners.push(owner);
        }
        required = _required;
    }


    receive() external payable {
        emit Deposit(msg.sender,msg.value);
     }

     function submit(address _to, uint256 _value, bytes calldata _data) external onlyOwner {
        transactions.push(transaction({
            to:_to,
            value:_value,
            data:_data,
            executed:false
        }));
        emit Submit(transactions.length - 1);
     }

     function approve(uint256 _txId) external onlyOwner notApproved(_txId) exists(_txId) notExecuted(_txId) {
        Approved[_txId][msg.sender] = true;
        emit Approve(msg.sender,_txId);
     }


     function _getApprovedcount(uint256 _txId) private view returns(uint256 count) {
        for(uint i = 0; i < owners.length; i++) {
            if(Approved[_txId][owners[i]]) {
                count++;
            }
        }
     }

    function execute(uint256 _txId) external exists(_txId) notExecuted(_txId) {
        require(_getApprovedcount(_txId) >= required, "approval < required");
        transaction storage Transaction = transactions[_txId];
        Transaction.executed = true;
        (bool success,) = Transaction.to.call{value:Transaction.value}(Transaction.data);
        require(success, "transaction failed");
        emit Execute(_txId);
    }


    function revoke(uint256 _txId) external exists(_txId) notExecuted(_txId) {
        require(Approved[_txId][msg.sender], "tx not approved ");
        Approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }

    







}