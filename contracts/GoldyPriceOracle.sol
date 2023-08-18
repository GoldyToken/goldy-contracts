// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract GoldyPriceOracle {

    // chain link pair to fetch price XAU/USD
    address public xauUsdOraclePair;
    // chain link pair to fetch price EUR/USD
    address public eurUsdOraclePair;
    // chain link pair to fetch price GBP/USD
    address public gbpUsdOraclePair;


    constructor(address _xauUsdOraclePair, address _eurUsdOraclePair, address _gbpUsdOraclePair) {
        xauUsdOraclePair = _xauUsdOraclePair;
        eurUsdOraclePair = _eurUsdOraclePair;
        gbpUsdOraclePair = _gbpUsdOraclePair;
    }

    // return the value of 0.01% ounce gold price in dollar in 18 decimals
    function getGoldyUsdPrice() external view returns (uint) {
        (, int256 price, , , ) = AggregatorV3Interface(xauUsdOraclePair).latestRoundData();
        return uint256(price) / 1e4;
    }

    // return the value of 1 ounce gold price in dollar in 18 decimals
    function getGoldOunceUsdPrice() external view returns (uint) {
        (, int256 price, , , ) = AggregatorV3Interface(xauUsdOraclePair).latestRoundData();
        return uint256(price);
    }

    // return the value of 1 gram gold price in dollar in 18 decimals
    function getGoldGramUsdPrice() external view returns (uint) {
        (, int256 price, , , ) = AggregatorV3Interface(xauUsdOraclePair).latestRoundData();
        return (uint256(price) * 1e4) / 283495;
    }

    // return the value of 1 gram gold price in dollar in 18 decimals
    function getGoldTroyOunceUsdPrice() external view returns (uint) {
        (, int256 price, , , ) = AggregatorV3Interface(xauUsdOraclePair).latestRoundData();
        return (uint256(price) * 1e7) / 311034768;
    }

/*
     euro prices functions
*/

    // return the value of 0.01% ounce gold price in euro in 18 decimals
    function getGoldyEuroPrice() external view returns (uint) {
        int256 price = getDerivedPrice(xauUsdOraclePair, eurUsdOraclePair, 18);
        return uint256(price) / 10000;
    }

    // return the value of 1 ounce gold price in euro in 18 decimals
    function getGoldOunceEuroPrice() external view returns (uint) {
        int256 price = getDerivedPrice(xauUsdOraclePair, eurUsdOraclePair, 18);
        return uint256(price);
    }

    // return the value of 1 gram gold price in euro in 18 decimals
    function getGoldGramEuroPrice() external view returns (uint) {
        int256 price = getDerivedPrice(xauUsdOraclePair, eurUsdOraclePair, 18);
        return (uint256(price) * 1e4) / 283495;
    }

    // return the value of 1 gram gold price in euro in 18 decimals
    function getGoldTroyOunceEuroPrice() external view returns (uint) {
        int256 price = getDerivedPrice(xauUsdOraclePair, eurUsdOraclePair, 18);
        return (uint256(price) * 1e7) / 311034768;
    }

/*
    gbp prices functions
*/

    // return the value of 0.01% ounce gold price in british pounds in 18 decimals
    function getGoldyGbpPrice() external view returns (uint) {
        int256 price = getDerivedPrice(xauUsdOraclePair, gbpUsdOraclePair, 18);
        return uint256(price) / 10000;
    }

    // return the value of 1 ounce gold price in british pounds in 18 decimals
    function getGoldOunceGbpPrice() external view returns (uint) {
        int256 price = getDerivedPrice(xauUsdOraclePair, gbpUsdOraclePair, 18);
        return uint256(price);
    }

    // return the value of 1 gram gold price in british pounds in 18 decimals
    function getGoldGramGbpPrice() external view returns (uint) {
        int256 price = getDerivedPrice(xauUsdOraclePair, gbpUsdOraclePair, 18);
        return (uint256(price) * 1e4) / 283495;
    }

    // return the value of 1 gram gold price in british pounds in 18 decimals
    function getGoldTroyOunceGbpPrice() external view returns (uint) {
        int256 price = getDerivedPrice(xauUsdOraclePair, gbpUsdOraclePair, 18);
        return (uint256(price) * 1e7) / 311034768;
    }



    function getDerivedPrice(
        address _base,
        address _quote,
        uint8 _decimals
    ) public view returns (int256) {
        require(
            _decimals > uint8(0) && _decimals <= uint8(18),
            "Invalid _decimals"
        );
        int256 decimals = int256(10 ** uint256(_decimals));
        (, int256 basePrice, , , ) = AggregatorV3Interface(_base)
            .latestRoundData();
        uint8 baseDecimals = AggregatorV3Interface(_base).decimals();
        basePrice = scalePrice(basePrice, baseDecimals, _decimals);

        (, int256 quotePrice, , , ) = AggregatorV3Interface(_quote)
            .latestRoundData();
        uint8 quoteDecimals = AggregatorV3Interface(_quote).decimals();
        quotePrice = scalePrice(quotePrice, quoteDecimals, _decimals);

        return (basePrice * decimals) / quotePrice;
    }

    function scalePrice(
        int256 _price,
        uint8 _priceDecimals,
        uint8 _decimals
    ) internal pure returns (int256) {
        if (_priceDecimals < _decimals) {
            return _price * int256(10 ** uint256(_decimals - _priceDecimals));
        } else if (_priceDecimals > _decimals) {
            return _price / int256(10 ** uint256(_priceDecimals - _decimals));
        }
        return _price;
    }

}