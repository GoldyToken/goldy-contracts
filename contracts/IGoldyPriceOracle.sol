// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IGoldyPriceOracle {

    function getGoldyUsdPrice() external view returns (uint);
    function getGoldOunceUsdPrice() external view returns (uint);
    function getGoldGramUsdPrice() external view returns (uint);
    function getGoldTroyOunceUsdPrice() external view returns (uint);

    function getGoldyEuroPrice() external view returns (uint);
    function getGoldOunceEuroPrice() external view returns (uint);
    function getGoldGramEuroPrice() external view returns (uint);
    function getGoldTroyOunceEuroPrice() external view returns (uint);

    function getGoldyGbpPrice() external view returns (uint);
    function getGoldOunceGbpPrice() external view returns (uint);
    function getGoldGramGbpPrice() external view returns (uint);
    function getGoldTroyOunceGbpPrice() external view returns (uint);

}
