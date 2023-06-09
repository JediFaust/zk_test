// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title Farming contract for zkSync
/// @author https://github.com/JediFaust
/// @notice You can use this contract for implement Farming on EVM compatible chains
/// @dev All functions tested successfully and have no errors

contract ZKFarming {  
    address public admin;
    uint256 public rewardPercent;
    uint256 public rewardRate;

    mapping(address => Deposit) private deposits;

    uint256 public constant MAXIMUM_REWARD_PERCENT = 1000;

    IERC20 public rewardToken;
    IERC20 public depositToken;

    struct Deposit {
        uint224 amount;
        uint32 depositTime;
    }

    /// @notice Deploys the contract with the initial parameters
    /// @dev Sets deployer as an Admin
    /// @param depositToken_ Address of Deposit Token 
    /// @param rewardToken_ Address of Reward Token
    /// @param rewardRate_ Rate of Rewarding in seconds
    /// @param rewardPercent_ Percent of Reward scaled up to 10
    constructor(
        address rewardToken_,
        address depositToken_,
        uint256 rewardPercent_,
        uint256 rewardRate_) {
            admin = msg.sender;
            rewardToken = IERC20(rewardToken_);
            depositToken = IERC20(depositToken_);
            rewardPercent = rewardPercent_;
            rewardRate = rewardRate_;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "FARM: Admin Only");
        _;
    }
    

    /// @notice Deposit function
    /// @dev Adds deposit amount to caller and,
    /// transfers amount of tokens to contract
    /// @dev emits Deposited event
    /// @param amount Amount of tokens to deposit
    /// @return true if transaction is successful
    function deposit(uint224 amount) external returns(bool) {
        require(amount > 0, "FARM: Zero Amount");

        Deposit storage d = deposits[msg.sender];

        require(d.depositTime == 0, "FARM: Already Deposited");

        depositToken.transferFrom(msg.sender, address(this), amount);

        d.amount = amount;
        d.depositTime = uint32(block.timestamp);

        emit Deposited(msg.sender, amount, block.timestamp);

        return true;
    }

    /// @notice Claims deposited tokens and reward tokens
    /// @dev Calculates the amount of reward,
    /// and transfers it to caller
    /// @dev emits Claimed event
    /// @return true if transaction is successful
    function claim() external returns(bool) {
        Deposit storage d = deposits[msg.sender];

        require(d.amount > 0, "FARM: No deposit");

        uint256 reward = 
            ((d.amount * rewardPercent) / 1000) *
            ((block.timestamp - d.depositTime) / rewardRate);
            
        if(reward > 0) { 
            rewardToken.transfer(msg.sender, reward);
        }

        depositToken.transfer(msg.sender, d.amount);

        d.amount = 0;
        d.depositTime = 0;

        emit Claimed(msg.sender, reward, block.timestamp);

        return true;
    }


    /// @notice Fills with Reward Tokens
    /// @dev emits RewardFilled event
    /// @param amount Amount of Reward Tokens to fill
    /// @return true if transaction is successful
    function fillRewards(uint256 amount) external onlyAdmin returns(bool) {
        require(amount > 0, "FARM: Zero Filment");
        rewardToken.transferFrom(msg.sender, address(this), amount);

        emit RewardFilled(amount, block.timestamp);

        return true;
    }

    /// @notice Sets the reward percent
    /// @dev emits RewardPercentChanged event
    /// @param newPercent Sets amount of Reward Percent scaled to 10
    /// for example 100% is 1000 and 0.1% is 1
    /// @return true if transaction is successful
    function setRewardPercent(uint256 newPercent) external onlyAdmin returns(bool) {
        require(
            newPercent > 0 && newPercent <= MAXIMUM_REWARD_PERCENT,
            "FARM: Invalid Reward Percent");

        emit RewardPercentChanged(rewardPercent, newPercent, block.timestamp);

        rewardPercent = newPercent;

        return true;
    }

    /// @notice Sets the reward rate time 
    /// @dev emits RewardRateChanged event
    /// @param newRate Sets Reward Rate in seconds
    /// @return true if transaction is successful
    function setRewardRate(uint256 newRate) external onlyAdmin returns(bool) {
        require(newRate > 0, "FARM: Zero Reward Rate");

        emit RewardRateChanged(rewardRate, newRate, block.timestamp);

        rewardRate = newRate;

        return true;
    }

    /// ---=== EVENTS ===---
    
    event Deposited(address indexed user, uint256 amount, uint256 indexed time);
    event Claimed(address indexed user, uint256 reward, uint256 indexed time);
    event RewardPercentChanged(uint256 oldPercent, uint256 newPercent, uint256 indexed time);
    event RewardRateChanged(uint256 oldRate, uint256 newRate, uint256 indexed time);
    event RewardFilled(uint256 amount, uint256 indexed time);
}
