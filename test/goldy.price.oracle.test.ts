import {
    loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";

import {ethers} from "hardhat";

describe("Goldy Price Oracle Contract", function () {
    async function deployTokenFixture() {
        const [owner, addr1, addr2] = await ethers.getSigners();

        const goldyPriceOracle = await ethers.deployContract("GoldyPriceOracle", ["0x7b219F57a8e9C7303204Af681e9fA69d17ef626f", "0x44390589104C9164407A0E0562a9DBe6C24A0E05", "0x73D9c953DaaB1c829D01E1FC0bd92e28ECfB66DB", "0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7", "0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7", "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e"]);

        // Fixtures can return anything you consider useful for your tests
        return { goldyPriceOracle, owner, addr1, addr2 };
    }

    it("Goldy Addresses Check", async function () {
        const { goldyPriceOracle, owner } = await loadFixture(deployTokenFixture);
        console.log("GoldyPriceOracle =>", goldyPriceOracle.target);
        console.log("GoldyPriceOracle xauUsdOraclePair =>", await goldyPriceOracle.xauUsdOraclePair());
        console.log("GoldyPriceOracle eurUsdOraclePair =>", await goldyPriceOracle.eurUsdOraclePair());
        console.log("GoldyPriceOracle gbpUsdOraclePair =>", await goldyPriceOracle.gbpUsdOraclePair());
        console.log("GoldyPriceOracle usdcUsdOraclePair =>", await goldyPriceOracle.usdcUsdOraclePair());
        console.log("GoldyPriceOracle usdtUsdOraclePair =>", await goldyPriceOracle.usdtUsdOraclePair());
        console.log("GoldyPriceOracle ethUsdOraclePair =>", await goldyPriceOracle.ethUsdOraclePair());
    });

});