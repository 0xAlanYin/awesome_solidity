//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @notice Permissionless staking contract for a single rewards program.
/// From the start of the program, to the end of the program, a fixed amount of rewards tokens will be distributed among stakers.
/// The rate at which rewards are distributed is constant over time, but proportional to the amount of tokens staked by each staker.
/// The contract expects to have received enough rewards tokens by the time they are claimable. The rewards tokens can only be recovered by claiming stakers.
/// This is a rewriting of [Unipool.sol](https://github.com/k06a/Unipool/blob/master/contracts/Unipool.sol), modified for clarity and simplified.
/// Careful if using non-standard ERC20 tokens, as they might break things.
// source: https://github.com/alcueca/staking/blob/b9349f3af585c03121c3627a57e0d4312c913c14/src/SimpleRewards.sol

contract SimpleRewards {
    using Cast for uint256; // for save gas

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 amount);
    event RewardsPerTokenUpdated(uint256 accumulatedRewardsPerToken);
    event UserRewardsUpdated(address indexed user, uint128 accumulatedRewards, uint128 rewardsPerToken);

    // this is global
    struct RewardsPerToken {
        uint128 accumulatedRewardsPerToken; // Accumulated rewards per token for the interval, notice scaled up by 1e18
        uint128 lastUpdated; // Last time the rewards per token accumulator was updated
    }

    // this is per user
    struct UserRewards {
        uint128 accumulatedRewards; // Accumulated rewards for the user until the checkpoint
        uint128 rewardsPerToken; // RewardsPerToken the last time the user rewards were updated
    }

    ERC20 public immutable stakingToken; // Token to be staked
    uint256 public totalStaked; // Total staked amount
    mapping(address => uint256) public userStake; // Amount staked per user

    ERC20 public immutable rewardsToken; // Token used as rewards
    uint256 public immutable rewardsRate; // Wei rewarded per second among all token holders
    uint256 public immutable rewardsStart; // Start of the rewards program
    uint256 public immutable rewardsEnd; // End of the rewards program

    RewardsPerToken public rewardsPerToken; // Accumulator to track rewards per token
    mapping(address => UserRewards) public accumulatedUserRewards; // Rewards accumulated per user

    uint256 private constant SCALE = 1e18; // avoid totalStaked too big to lost accuracy

    constructor(
        address stakingToken_,
        address rewardsToken_,
        uint256 rewardsStart_,
        uint256 rewardsEnd_,
        uint256 totalRewards
    ) {
        stakingToken = ERC20(stakingToken_);
        rewardsToken = ERC20(rewardsToken_);

        require(rewardsStart_ < rewardsEnd_, "invalid duration");
        rewardsStart = rewardsStart_;
        rewardsEnd = rewardsEnd_;
        rewardsRate = totalRewards / (rewardsEnd_ - rewardsStart_);
        rewardsPerToken.lastUpdated = rewardsStart_.u128();
    }

    // stake
    function stake(uint256 amount) public {
        address user = msg.sender;
        // update global rewardsPerToken
        // update userRewards
        _updateUserRewards(user);

        // update userStaked
        userStake[user] += amount;

        // update totalStaked
        totalStaked += amount;

        // transfer
        SafeERC20.safeTransferFrom(stakingToken, user, address(this), amount);

        emit Staked(user, amount);
    }

    // unstake
    function unstake(uint256 amount) public {
        address user = msg.sender;
        // update global rewardsPerToken
        // update userRewards
        _updateUserRewards(user);

        // update userStaked
        userStake[user] -= amount;

        // update totalStaked
        totalStaked -= amount;

        // transer
        SafeERC20.safeTransfer(stakingToken, user, amount);

        // event
        emit Unstaked(user, amount);
    }

    // claim
    function claim() public returns (uint256) {
        address user = msg.sender;
        // update global rewardsPerToken
        // update userRewards
        uint128 claimed = _updateUserRewards(user).accumulatedRewards;

        _claim(user, claimed);

        return claimed;
    }

    /// @notice Calculate and return current rewards per token.
    function currentRewardsPerToken() public view returns (uint256) {
        return _calculateRewardsPerToken(rewardsPerToken).accumulatedRewardsPerToken;
    }

    /// @notice Calculate and return current rewards for a user.
    /// @dev This repeats the logic used on transactions, but doesn't update the storage.
    function currentUserRewards(address user) public view returns (uint256) {
        UserRewards memory userReward_ = accumulatedUserRewards[user];
        RewardsPerToken memory rewardsPerToken_ = _calculateRewardsPerToken(rewardsPerToken);
        return userReward_.accumulatedRewards
            + _calculateUserRewards(
                rewardsPerToken_.accumulatedRewardsPerToken, userReward_.accumulatedRewards, userStake[user]
            );
    }

    function _claim(address user, uint256 amount) private {
        uint128 userAccumulatedRewardsAvailable = _updateUserRewards(user).accumulatedRewards;

        // This line would panic if the user doesn't have enough rewards accumulated
        accumulatedUserRewards[user].accumulatedRewards = (userAccumulatedRewardsAvailable - amount).u128();

        // This line would panic if the contract doesn't have enough rewards tokens
        SafeERC20.safeTransfer(rewardsToken, user, amount);

        emit Claimed(user, amount);
    }

    function _updateUserRewards(address user) private returns (UserRewards memory) {
        // update global rewardsPerToken
        RewardsPerToken memory rewardsPerToken_ = _updateRewardsPerToken();

        UserRewards memory userRewards_ = accumulatedUserRewards[user];

        // calculate and update the new value user rewards.
        userRewards_.accumulatedRewards += _calculateUserRewards(
            rewardsPerToken_.accumulatedRewardsPerToken, userRewards_.rewardsPerToken, userStake[user]
        ).u128();
        userRewards_.rewardsPerToken = rewardsPerToken_.accumulatedRewardsPerToken;

        accumulatedUserRewards[user] = userRewards_;
        emit UserRewardsUpdated(user, userRewards_.accumulatedRewards, userRewards_.rewardsPerToken);

        return userRewards_;
    }

    function _calculateUserRewards(
        uint128 accumulatedRewardsPerToken,
        uint128 userAccumulatedRewardsPerToken,
        uint256 userStake_
    ) private pure returns (uint256) {
        return (accumulatedRewardsPerToken - userAccumulatedRewardsPerToken) * userStake_ / SCALE; // We must scale down the rewards by the precision factor
    }

    function _updateRewardsPerToken() private returns (RewardsPerToken memory) {
        RewardsPerToken memory rewardsPerTokenIn = rewardsPerToken;
        RewardsPerToken memory rewardsPerTokenOut = _calculateRewardsPerToken(rewardsPerTokenIn);

        // skip the storage changes if already updated in the same block, or if the program has ended and was updated at the end
        if (rewardsPerTokenIn.lastUpdated == rewardsPerTokenOut.lastUpdated) {
            return rewardsPerTokenOut;
        }

        // update userRewards
        rewardsPerToken = rewardsPerTokenOut;
        emit RewardsPerTokenUpdated(rewardsPerTokenOut.accumulatedRewardsPerToken);

        return rewardsPerTokenOut;
    }

    /// @notice Update the rewards per token accumulator according to the rate, the time elapsed since the last update, and the current total staked amount.
    function _calculateRewardsPerToken(RewardsPerToken memory rewardsPerTokenIn)
        private
        view
        returns (RewardsPerToken memory)
    {
        RewardsPerToken memory rewardsPerTokenOut =
            RewardsPerToken(rewardsPerTokenIn.accumulatedRewardsPerToken, rewardsPerTokenIn.lastUpdated);

        // if the program has not started,no change
        if (block.timestamp < rewardsStart) {
            return rewardsPerTokenOut;
        }

        // Stop accumulating at the end of the rewards interval
        uint256 updateTime = block.timestamp < rewardsEnd ? block.timestamp : rewardsEnd;
        uint256 elapsed = updateTime - rewardsPerTokenIn.lastUpdated;

        // if no time has passed,no change
        if (elapsed == 0) {
            return rewardsPerTokenOut;
        }
        rewardsPerTokenOut.lastUpdated = updateTime.u128();

        // If there are no stakers we just change the last update time, the rewards for intervals without stakers are not accumulated
        uint256 totalStaked_ = totalStaked;
        if (totalStaked_ == 0) {
            return rewardsPerTokenOut;
        }

        // calculate and update the new value of accumulatedRewardsPerToken
        rewardsPerTokenOut.accumulatedRewardsPerToken =
            (rewardsPerTokenOut.accumulatedRewardsPerToken + rewardsRate * elapsed * SCALE / totalStaked_).u128();
        return rewardsPerTokenOut;
    }
}

library Cast {
    function u128(uint256 x) internal pure returns (uint128 y) {
        require(x <= type(uint128).max, "Cast overflow");
        y = uint128(x);
    }
}
