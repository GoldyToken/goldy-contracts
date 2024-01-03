import {
    loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";

import {ethers} from "hardhat";
import {max} from "hardhat/internal/util/bigint";

describe("ICO contract", function () {
    async function deployTokenFixture() {
        const [owner, addr1, addr2] = await ethers.getSigners();

        const goldyToken = await ethers.deployContract("GoldyToken", ['GOLDY', 'GOLDY']);
        const usdcToken = await ethers.deployContract("GoldyToken", ['USDC Token', 'USDC']);
        const usdtToken = await ethers.deployContract("GoldyToken", ['USDT', 'USDT Token']);
        const eurocToken = await ethers.deployContract("GoldyToken", ['EUROC', 'EUROC Token']);
        const goldyPriceOracle = await ethers.deployContract("GoldyPriceOracle", ["0x7b219F57a8e9C7303204Af681e9fA69d17ef626f", "0x44390589104C9164407A0E0562a9DBe6C24A0E05", "0x73D9c953DaaB1c829D01E1FC0bd92e28ECfB66DB", "0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7", "0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7", "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e"]);
        const ico = await ethers.deployContract("ICO", [goldyPriceOracle.target, usdcToken.target, usdtToken.target, eurocToken.target, owner.address]);

        // Fixtures can return anything you consider useful for your tests
        return { goldyToken, usdcToken, usdtToken, eurocToken, goldyPriceOracle, ico, owner, addr1, addr2 };
    }

    it("create sale should give error with refinery empty", async function () {
        const { goldyToken, ico, owner } = await loadFixture(deployTokenFixture);
        // Get the current timestamp in milliseconds
        const currentTimestamp = new Date().getTime();

        // Convert milliseconds to seconds (Unix timestamp is usually in seconds)
        const startDate = Math.floor(currentTimestamp / 1000);
        const endDate = startDate + 3600;
        const maxToken = BigInt(1000 * 1e18);
        const amlCheck = BigInt(100 * 1e18);
        await expect(ico.connect(owner).createSale(goldyToken.target, startDate, endDate, maxToken, true, amlCheck)).to.be.revertedWith("RE");
    });

    it("add refinery connect and create sale with extra token revert with error", async function () {
        const { goldyToken, ico, owner } = await loadFixture(deployTokenFixture);
        await ico.connect(owner).addRefineryConnectDetails(Math.floor(new Date().getTime() / 1000), 12321, 100, 1000, 123343, ['GOLDY-12355'], [1]);
        const currentTimestamp = new Date().getTime();
        const startDate = Math.floor(currentTimestamp / 1000);
        const endDate = startDate + 3600;
        const maxToken = BigInt(10001 * 1e18);
        const amlCheck = BigInt(100 * 1e18);
        await goldyToken.connect(owner).approve(ico.target, maxToken);
        await expect(ico.connect(owner).createSale(goldyToken.target, startDate, endDate, maxToken, true, amlCheck)).to.be.revertedWith("NGB");

    });

    it("add refinery connect and create sale", async function () {
        const { goldyToken, ico, owner } = await loadFixture(deployTokenFixture);
        await ico.connect(owner).addRefineryConnectDetails(Math.floor(new Date().getTime() / 1000), 12321, 100, 1000, 123343, ['GOLDY-12355'], [1]);
        const currentTimestamp = new Date().getTime();
        const startDate = Math.floor(currentTimestamp / 1000);
        const endDate = startDate + 3600;
        const maxToken = BigInt(10000 * 1e18);
        const amlCheck = BigInt(100 * 1e18);
        await goldyToken.connect(owner).approve(ico.target, maxToken);
        await expect(ico.connect(owner).createSale(goldyToken.target, startDate, endDate, maxToken, true, amlCheck)).to.emit(ico, "CreateSale")
            .withArgs(0, goldyToken.target, startDate, endDate, maxToken, true, amlCheck);

    });

    it("add refinery connect and create sale and purchase all token", async function () {
        const { goldyToken, usdtToken, goldyPriceOracle, ico, owner } = await loadFixture(deployTokenFixture);
        await ico.connect(owner).addRefineryConnectDetails(Math.floor(new Date().getTime() / 1000), 12321, 100, 1000, 123343, ['GOLDY-12355'], [1]);
        const block = await ethers.provider.getBlock('latest');
        // @ts-ignore
        const startDate = block?.timestamp - 100;
        const endDate = startDate + 3600;
        const maxToken = BigInt(10000 * 1e18);
        const amlCheck = BigInt(100 * 1e18);
        await goldyToken.connect(owner).approve(ico.target, maxToken);
        await expect(ico.connect(owner).createSale(goldyToken.target, startDate, endDate, maxToken, false, amlCheck)).to.emit(ico, "CreateSale")
            .withArgs(0, goldyToken.target, startDate, endDate, maxToken, false, amlCheck);
        const totalUSDT = BigInt(10000) * await goldyPriceOracle.getGoldyUSDTPrice();
        await usdtToken.connect(owner).approve(ico.target, totalUSDT);
        await expect(ico.connect(owner).buyToken( totalUSDT, 1)).to.emit(ico, "BuyToken").withArgs(owner.address, 1, totalUSDT, BigInt(10000 * 1e18), false, "native function", "GOLDY-12355", "1");
    });

    it("add refinery connect and create sale and again create sale burn pending tokens and revert error with NGB", async function () {
        const { goldyToken, usdtToken, goldyPriceOracle, ico, owner } = await loadFixture(deployTokenFixture);
        await ico.connect(owner).addRefineryConnectDetails(Math.floor(new Date().getTime() / 1000), 12321, 100, 1000, 123343, ['GOLDY-12355'], [1]);
        const block = await ethers.provider.getBlock('latest');
        // @ts-ignore
        const startDate = block?.timestamp - 100;
        const endDate = startDate + 3600;
        const maxToken = BigInt(10000 * 1e18);
        const amlCheck = BigInt(100 * 1e18);
        await goldyToken.connect(owner).approve(ico.target, maxToken);
        await expect(ico.connect(owner).createSale(goldyToken.target, startDate, endDate, maxToken, false, amlCheck)).to.emit(ico, "CreateSale")
            .withArgs(0, goldyToken.target, startDate, endDate, maxToken, false, amlCheck);
        const totalUSDT = BigInt(5000) * await goldyPriceOracle.getGoldyUSDTPrice();
        await usdtToken.connect(owner).approve(ico.target, totalUSDT);
        await expect(ico.connect(owner).buyToken( totalUSDT, 1)).to.emit(ico, "BuyToken").withArgs(owner.address, 1, totalUSDT, BigInt(5000 * 1e18), false, "native function", "GOLDY-12355", "1");


        // second sale creating
        await goldyToken.connect(owner).approve(ico.target, maxToken);
        await expect(ico.connect(owner).createSale(goldyToken.target, startDate, endDate, maxToken, false, amlCheck)).to.be.revertedWith("NGB");
    });

    it("add refinery connect and create sale and again create sale burn pending tokens and add refinery 3 bar details with 1oz each different bar serial purchase tokens token should attach with correct bar details", async function () {
        const { goldyToken, usdtToken, goldyPriceOracle, ico, owner } = await loadFixture(deployTokenFixture);
        await ico.connect(owner).addRefineryConnectDetails(Math.floor(new Date().getTime() / 1000), 12321, 100, 1000, 123343, ['GOLDY-12355'], [1]);
        const block = await ethers.provider.getBlock('latest');
        // @ts-ignore
        const startDate = block?.timestamp - 100;
        const endDate = startDate + 3600;
        const maxToken = BigInt(10000 * 1e18);
        const amlCheck = BigInt(100 * 1e18);
        await goldyToken.connect(owner).approve(ico.target, maxToken);
        await expect(ico.connect(owner).createSale(goldyToken.target, startDate, endDate, maxToken, false, amlCheck)).to.emit(ico, "CreateSale")
            .withArgs(0, goldyToken.target, startDate, endDate, maxToken, false, amlCheck);
        const totalUSDT = BigInt(5000) * await goldyPriceOracle.getGoldyUSDTPrice();
        await usdtToken.connect(owner).approve(ico.target, totalUSDT);
        await expect(ico.connect(owner).buyToken( totalUSDT, 1)).to.emit(ico, "BuyToken").withArgs(owner.address, 1, totalUSDT, BigInt(5000 * 1e18), false, "native function", "GOLDY-12355", "1");


        // second sale creating
        await ico.connect(owner).addRefineryConnectDetails(Math.floor(new Date().getTime() / 1000), 12321, 100, 1000, 123343, ['GOLDY-12356', 'GOLDY-12357', 'GOLDY-12358'], [1, 1, 1]);
        await goldyToken.connect(owner).approve(ico.target, maxToken + BigInt(6000 * 1e18));
        await expect(ico.connect(owner).createSale(goldyToken.target, startDate, endDate, maxToken + BigInt(6000 * 1e18), false, amlCheck)).to.emit(ico, "CreateSale")
            .withArgs(1, goldyToken.target, startDate, endDate, maxToken + BigInt(6000 * 1e18), false, amlCheck);
        expect(await goldyToken.balanceOf(ico.target)).to.equal(maxToken + BigInt(6000 * 1e18));


        const total2USDT = BigInt(5000) * await goldyPriceOracle.getGoldyUSDTPrice();
        await usdtToken.connect(owner).approve(ico.target, total2USDT);
        await expect(ico.connect(owner).buyToken( total2USDT, 1)).to.emit(ico, "BuyToken").withArgs(owner.address, 1, total2USDT, BigInt(5000 * 1e18), false, "native function", "GOLDY-12355", "1");

        const total3USDT = BigInt(2000) * await goldyPriceOracle.getGoldyUSDTPrice();
        await usdtToken.connect(owner).approve(ico.target, total3USDT);
        await expect(ico.connect(owner).buyToken( total3USDT, 1)).to.emit(ico, "BuyToken").withArgs(owner.address, 1, total3USDT, BigInt(2000 * 1e18), false, "native function", "GOLDY-12356", "1");

        const total4USDT = BigInt(4000) * await goldyPriceOracle.getGoldyUSDTPrice();
        await usdtToken.connect(owner).approve(ico.target, total4USDT);
        await expect(ico.connect(owner).buyToken( total4USDT, 1)).to.emit(ico, "BuyToken").withArgs(owner.address, 1, total4USDT, BigInt(4000 * 1e18), false, "native function", "GOLDY-12356", "1");

        const total5USDT = BigInt(4000) * await goldyPriceOracle.getGoldyUSDTPrice();
        await usdtToken.connect(owner).approve(ico.target, total5USDT);
        await expect(ico.connect(owner).buyToken( total5USDT, 1)).to.emit(ico, "BuyToken").withArgs(owner.address, 1, total5USDT, BigInt(4000 * 1e18), false, "native function", "GOLDY-12356", "1");

        const total6USDT = BigInt(1) * await goldyPriceOracle.getGoldyUSDTPrice();
        await usdtToken.connect(owner).approve(ico.target, total6USDT);
        await expect(ico.connect(owner).buyToken( total6USDT, 1)).to.emit(ico, "BuyToken").withArgs(owner.address, 1, total6USDT, BigInt(1e18), false, "native function", "GOLDY-12357", "1");

    });

});