//SPDX-License-Identifier: LicenseRef-LICENSE
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Vesting {
    using Counters for Counters.Counter;

    struct VestingPool {
        uint32 period; // in seconds
        uint32 cliff; // unix timestamp
        uint16 periodBP; // in bp
        uint16 releasedBP; // in bp
        uint16 firstReleaseInBP; // in bp
        uint amount; // total amount
        address user;
        IERC20 token;
    }

    Counters.Counter public _vestingPoolIdTracker;
    mapping (uint => VestingPool) public vestingPools;
    mapping (address => uint[]) public vestingIds;
    uint public totalVestedTokenAmount;
    bool public isVestingActive;
    address public owner;

    constructor() {
        owner = msg.sender;
        isVestingActive = true;
    }

    event LockToken (uint32 period, uint32 cliff, uint16 periodBP, uint16 firstReleaseInBP, uint amount, address user, address token);
    modifier onlyOwner(uint vestingPoolId) {
        VestingPool memory vestingPool = vestingPools[vestingPoolId];
        require(msg.sender == vestingPool.user, 'VS:100'); //Vesting: only owner is allowed to withdraw
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner, 'Only Admin');
        _;
    }

    function getCorrectAmount(IERC20 token, uint _amount) internal returns (uint) {
        uint beforeBalance = token.balanceOf(address(this));
        require(token.transferFrom(msg.sender, address(this), _amount), 'VS:101');
        uint afterBalance = token.balanceOf(address(this));

        return afterBalance - beforeBalance;
    }

    function getPercent(uint amount, uint bp) internal pure returns (uint) {
        require(bp <= 10000, 'VS:102'); //Vesting: BP must be <= 10000
        return (amount * bp) / 10000;
    }

    function getAdjustedAmount(uint totalAmount, uint amount) internal pure returns (uint, uint) {
        uint approxBp = (amount * 10000) / totalAmount;
        uint correctedAmount = getPercent(totalAmount, approxBp);

        return (approxBp, correctedAmount);
    }

    function availableToWithdraw(VestingPool memory vestingPool) public view returns (uint, uint) {

        if(block.timestamp <= uint(vestingPool.cliff)) return (0, 0);

        uint availableAmountInBP = (
            (
                ((block.timestamp - uint(vestingPool.cliff)) / uint(vestingPool.period)) * uint(vestingPool.periodBP)
            ) + uint(vestingPool.firstReleaseInBP)
        ) - uint(vestingPool.releasedBP);

        if (availableAmountInBP + vestingPool.releasedBP > 10000) {
            availableAmountInBP = 10000 - vestingPool.releasedBP;
        }

        uint availableAmountInToken = getPercent(vestingPool.amount, availableAmountInBP);

        return (availableAmountInBP, availableAmountInToken);
    }

    function create(uint32 period, uint32 cliff, uint16 periodBP, uint16 firstReleaseInBP, uint amount, address user, address _token) public returns (uint) {
        //        require(block.timestamp <= uint(cliff), 'Vesting: cliff cannot be in past');
        require(isVestingActive, 'InActive');
        require(10000 >= uint(firstReleaseInBP) && 0 <= uint(firstReleaseInBP), 'VS:103'); //'Vesting: First release cannot be more then 100% and less then 0%'
        require(10000 >= uint(periodBP) && 0 <= uint(periodBP), 'VS:104'); //'Vesting: Period amount release cannot be more then 100% and less then to 0%'

        IERC20 token = IERC20(_token);

        uint vestingPoolIdToAssign = _vestingPoolIdTracker.current();
        _vestingPoolIdTracker.increment();

        VestingPool storage vestingPool = vestingPools[vestingPoolIdToAssign];
        vestingPool.amount = getCorrectAmount(token, amount); // To support fee enabled tokens
        vestingPool.user = user;
        vestingPool.cliff = cliff;
        vestingPool.period = period;
        vestingPool.periodBP = periodBP;
        vestingPool.token = token;
        vestingPool.firstReleaseInBP = firstReleaseInBP;

        if (firstReleaseInBP > 0) {
            uint tokensToRelease = getPercent(amount, firstReleaseInBP);
            require(token.transfer(user, tokensToRelease), 'VS:101'); //Vesting: Token transfer failed
            vestingPool.releasedBP = firstReleaseInBP;
        }

        _withdraw(vestingPoolIdToAssign);
        // store all vesting pool ids against user address
        vestingIds[user].push(vestingPoolIdToAssign);
        totalVestedTokenAmount += amount;
        emit LockToken(period, cliff, periodBP, firstReleaseInBP, amount, user, _token);
        return vestingPoolIdToAssign;
    }

    function _withdraw(uint vestingPoolId) internal {
        (uint availableAmountInBP, uint availableAmountInToken) = availableToWithdraw(vestingPools[vestingPoolId]);
        VestingPool storage vestingPool = vestingPools[vestingPoolId];
        if (availableAmountInBP > 0) {
            require(vestingPool.token.transfer(vestingPool.user, availableAmountInToken), 'VS:101'); //'Vesting: Token transfer failed'
            vestingPool.releasedBP += uint16(availableAmountInBP);
        }
    }

    function withdraw(uint vestingPoolId) public onlyOwner(vestingPoolId) {
        _withdraw(vestingPoolId);
    }

    // Fallback
    function withdrawWithSpecificAmount(uint vestingPoolId, uint amount) public onlyOwner(vestingPoolId) {
        (, uint availableAmountInToken) = availableToWithdraw(vestingPools[vestingPoolId]);

        require(amount <= availableAmountInToken, 'Vesting: wut?');

        VestingPool storage vestingPool = vestingPools[vestingPoolId];

        (uint approxBP, uint correctedAmount) = getAdjustedAmount(vestingPool.amount, amount);

        require(vestingPool.token.transfer(msg.sender, correctedAmount), 'VS:101'); //'Vesting: Token transfer failed'
        vestingPool.releasedBP += uint16(approxBP);
    }

    function getUserVestingPoolIds (address _user) external view returns (uint[] memory) {
        return vestingIds[_user];
    }

    function toggleVestingStatus() external onlyAdmin {
        isVestingActive = !isVestingActive;
    }

}

