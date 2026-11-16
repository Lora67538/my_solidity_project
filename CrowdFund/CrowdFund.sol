// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.23;

interface IERC20 {
function transfer(address, uint256) external returns (bool);
function transferFrom(address, address, uint256) external returns (bool);
}


contract CrowdFund {
    event Launch(uint indexed id, address indexed creator, uint goal, uint32 startAt, uint32 endAt);
    event Cancel(uint indexed id);
    event Pledge(uint indexed id, address indexed sender, uint amount);
    event Unpledge(uint indexed id, address indexed sender, uint amount);
    event Claim(uint indexed id, address indexed sender, uint amount);
    event Refund(uint indexed id, address indexed sender, uint amount);

    struct Campaign {
        address creator;
        uint goal;
        uint pledged;
        uint32 startAt;
        uint32 endAt;
        bool claimed;
    }
    IERC20 public immutable token;
    uint public count;
    mapping(uint => Campaign) public Campaigns;
    mapping(uint => mapping(address => uint)) public pledgeAmounts;
    constructor(address _token) {
        token = IERC20(_token);
    }

    // 发起众筹（发起者）
    function Launch(uint _goal,uint32 startOffset,uint32 endOfset) external {
        require(endOfset <= 30 days, "endOfset must be less than 30 days");
        require(startOffset < endOfset, "startAt > endAt");
        require(_goal > 0, "goal must be greater than 0");
        count++;
        uint32 _startAt = uint32(block.timestamp) + startOffset;
        uint32 _endAt = _startAt + endOfset;
        Campaigns[count] = Campaign({
            creator: msg.sender,
            goal: _goal,
            pledged: 0,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false
        });
        emit Launch(count, msg.sender, _goal, _startAt, _endAt);
    }
    // 取消众筹（发起者）
    function cancel(uint _id) external {
        Campaign memory campaign = Campaigns[_id];
        require(msg.sender == campaign.creator, "not creator");
        require(block.timestamp < campaign.startAt, "already started");
        delete Campaigns[_id];
        emit Cancel(_id);
    }
    // 认捐资金（支持者）
    function pledge(uint _id, uint amount) external {
        Campaign storage campaign = Campaigns[_id];
        require(block.timestamp >= campaign.startAt, "not started");
        require(block.timestamp <= campaign.endAt, "ended");
        require(amount > 0, "amount must be greater than 0");
        pledgeAmounts[_id][msg.sender] += amount;
        campaign.pledged += amount;
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "transfer failed");
        emit Pledge(_id, msg.sender, amount);
    }
    // 撤回认捐（支持者）
    function unpledge(uint _id, uint amount) external {
        Campaign storage campaign = Campaigns[_id];
        require(block.timestamp < campaign.endAt, "ended");
        require(pledgeAmounts[_id][msg.sender] >= amount, "not enough pledged");
        pledgeAmounts[_id][msg.sender] -= amount;
        campaign.pledged -= amount;
        bool success = token.transfer(msg.sender, amount);
        require(success, "transfer failed");
        emit Unpledge(count, msg.sender, amount);
    }
    // 提取资金（发起者）
    function claim(uint _id) external {
        Campaign storage campaign = Campaigns[_id];
        require(msg.sender == campaign.creator, "not creator");
        require(block.timestamp > campaign.endAt, "not ended");
        require(!campaign.claimed, "already claimed");
        require(campaign.pledged >= campaign.goal, "pledged < goal");
        campaign.claimed = true;
        bool success = token.transfer(msg.sender, campaign.pledged);
        require(success, "transfer failed");
    }
    // 失败退款（支持者）
    function refund(uint _id) external {
        Campaign storage campaign = Campaigns[_id];
        require(block.timestamp > campaign.endAt, "not ended");
        require(!campaign.claimed, "already claimed");
        uint amount = pledgeAmounts[_id][msg.sender];
        pledgeAmounts[_id][msg.sender] = 0;
        campaign.pledged -= amount;
        bool success = token.transfer(msg.sender, amount);
        require(success, "transfer failed");
    }
}