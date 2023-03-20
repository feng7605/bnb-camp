// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import ERC20 Interface
import "./ERC20.sol";

// Liquidity Mining Contract
contract LiquidityMining {
    IERC20 public token; // The token being mined
    IERC20 public lpToken; // The LP token being staked
    address public owner; // Owner of the contract
    uint256 public rewardRate; // Rewards per second
    uint256 public totalRewards; // Total rewards amount
    uint256 public startTime; // Mining start time
    uint256 public endTime; // Mining end time
    uint256 public lastUpdateTime; // Last rewards update time
    uint256 public rewardPerTokenStored; // Rewards per LP token stored
    mapping(address => uint256) public userRewardPerTokenPaid; // Rewards per LP token paid to users
    mapping(address => uint256) public rewards; // Total rewards earned by users
    mapping(address => uint256) public stakedBalance; // LP tokens staked by users
    
    // Events
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event RewardAdded(uint256 reward);
    
    // Constructor
    constructor(IERC20 _token, IERC20 _lpToken, uint256 _rewardRate, uint256 _totalRewards, uint256 _duration) {
        token = _token;
        lpToken = _lpToken;
        owner = msg.sender;
        rewardRate = _rewardRate;
        totalRewards = _totalRewards;
        startTime = block.timestamp;
        endTime = startTime + _duration;
        lastUpdateTime = startTime;
    }
    
    // Stake LP tokens
    function stake(uint256 amount) public {
        require(amount > 0, "Cannot stake 0");
        updateReward(msg.sender);
        lpToken.transferFrom(msg.sender, address(this), amount);
        stakedBalance[msg.sender] += amount;
        emit Staked(msg.sender, amount);
    }
    
    // Withdraw LP tokens
    function withdraw(uint256 amount) public {
        require(amount > 0, "Cannot withdraw 0");
        updateReward(msg.sender);
        stakedBalance[msg.sender] -= amount;
        lpToken.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }
    
    // Claim rewards
    function claim() public {
        updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards to claim");
        rewards[msg.sender] = 0;
        token.transfer(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
    }
    
    // Update rewards for user
    function updateReward(address account) internal {
        uint256 lastRewardUpdateTime = lastUpdateTime;
        if (block.timestamp > lastRewardUpdateTime) {
            uint256 lpTokenSupply = lpToken.balanceOf(address(this));
            uint256 time = block.timestamp - lastRewardUpdateTime;
            uint256 reward = time * rewardRate;
            if (lpTokenSupply > 0) {
                rewardPerTokenStored += reward * 1e18 / lpTokenSupply;
            }
            lastUpdateTime = block.timestamp;
        }
        if (account != address(0)) {
            rewards[account] += stakedBalance[account] * (rewardPerTokenStored - userRewardPerTokenPaid[account]) / 1e18;
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
}
}

// Add more rewards to the pool
function addRewards(uint256 amount) public {
    require(msg.sender == owner, "Only owner can add rewards");
    token.transferFrom(msg.sender, address(this), amount);
    totalRewards += amount;
    emit RewardAdded(amount);
}

// Update rewards duration
function updateRewardsDuration(uint256 newDuration) public {
    require(msg.sender == owner, "Only owner can update rewards duration");
    require(block.timestamp < endTime, "Mining has already ended");
    uint256 remainingTime = endTime - block.timestamp;
    require(newDuration > remainingTime, "New duration must be longer than remaining time");
    uint256 newEndTime = block.timestamp + newDuration;
    endTime = newEndTime;
    emit RewardsDurationUpdated(newDuration);
}

// End mining and withdraw remaining rewards
function endMining() public {
    require(msg.sender == owner, "Only owner can end mining");
    require(block.timestamp >= endTime, "Mining has not yet ended");
    uint256 lpTokenBalance = lpToken.balanceOf(address(this));
    lpToken.transfer(owner, lpTokenBalance);
    uint256 remainingRewards = totalRewards - token.balanceOf(address(this));
    if (remainingRewards > 0) {
        token.transfer(owner, remainingRewards);
    }
}
}