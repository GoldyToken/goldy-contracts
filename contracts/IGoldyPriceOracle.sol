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

    function getGoldyUSDCPrice() external view returns (uint);
    function getGoldOunceUSDCPrice() external view returns (uint);
    function getGoldGramUSDCPrice() external view returns (uint);
    function getGoldTroyOunceUSDCPrice() external view returns (uint);

    function getGoldyUSDTPrice() external view returns (uint);
    function getGoldOunceUSDTPrice() external view returns (uint);
    function getGoldGramUSDTPrice() external view returns (uint);
    function getGoldTroyOunceUSDTPrice() external view returns (uint);

    function getGoldyETHPrice() external view returns (uint);
    function getGoldOunceETHPrice() external view returns (uint);
    function getGoldGramETHPrice() external view returns (uint);
    function getGoldTroyOunceETHPrice() external view returns (uint);

}
