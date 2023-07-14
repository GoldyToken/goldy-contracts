// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract GoldXPriceOracle {

    // chain link pair to fetch price XAU/USD
    address public oraclePair;
    constructor(address _oraclePair) {
        oraclePair = _oraclePair;
    }

    // return the value of 0.01% ounce gold price in dollar in 18 decimals
    function getGoldXPrice() external view returns (uint) {
        (, int256 price, , , ) = AggregatorV3Interface(oraclePair).latestRoundData();
        return uint256(price) / 10000;
    }

    // return the value of 1 ounce gold price in dollar in 18 decimals
    function getGoldOuncePrice() external view returns (uint) {
        (, int256 price, , , ) = AggregatorV3Interface(oraclePair).latestRoundData();
        return uint256(price);
    }

    // return the value of 1 gram gold price in dollar in 18 decimals
    function getGoldGramPrice() external view returns (uint) {
        (, int256 price, , , ) = AggregatorV3Interface(oraclePair).latestRoundData();
        return (uint256(price) * 10000) / 283495;
    }

}
