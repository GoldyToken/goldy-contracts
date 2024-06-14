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
        const goldyPriceOracle = await ethers.deployContract("GoldyPriceOracle", ["0xC5981F461d74c46eB4b0CF3f4Ec79f025573B0Ea", "0x1a81afB8146aeFfCFc5E50e8479e826E7D55b910", "0x91FAB41F5f3bE955963a986366edAcff1aaeaa83", "0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E", "0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E", "0x694AA1769357215DE4FAC081bf1f309aDC325306"]);
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
        await expect(ico.connect(owner).createSale(goldyToken.target, startDate, endDate, maxToken, true)).to.be.revertedWith("RE");
    });

    it("add refinery connect and create sale with extra token revert with error", async function () {
        const { goldyToken, ico, owner } = await loadFixture(deployTokenFixture);
        await ico.connect(owner).addRefineryConnectDetails(Math.floor(new Date().getTime() / 1000), 12321, 100, 1000, 123343, ['GOLDY-12355'], [1]);
        const currentTimestamp = new Date().getTime();
        const startDate = Math.floor(currentTimestamp / 1000);
        const endDate = startDate + 3600;
        const maxToken = BigInt(10001 * 1e18);
        await goldyToken.connect(owner).approve(ico.target, maxToken);
        await expect(ico.connect(owner).createSale(goldyToken.target, startDate, endDate, maxToken, true)).to.be.revertedWith("NGB");

    });

    it("add refinery connect and create sale", async function () {
        const { goldyToken, ico, owner } = await loadFixture(deployTokenFixture);
        await ico.connect(owner).addRefineryConnectDetails(Math.floor(new Date().getTime() / 1000), 12321, 100, 1000, 123343, ['GOLDY-12355'], [100]);
        const currentTimestamp = new Date().getTime();
        const startDate = Math.floor(currentTimestamp / 1000);
        const endDate = startDate + 3600;
        const maxToken = BigInt(10000 * 1e18);
        await goldyToken.connect(owner).approve(ico.target, maxToken);
        await expect(ico.connect(owner).createSale(goldyToken.target, startDate, endDate, maxToken, true)).to.emit(ico, "CreateSale")
            .withArgs(0, goldyToken.target, startDate, endDate, maxToken, true)

    });

    it("add refinery connect and create sale and purchase all token", async function () {
        const { goldyToken, usdtToken, goldyPriceOracle, ico, owner } = await loadFixture(deployTokenFixture);
        await ico.connect(owner).addRefineryConnectDetails(Math.floor(new Date().getTime() / 1000), 12321, 100, 1000, 123343, ['GOLDY-12355'], [100]);
        const block = await ethers.provider.getBlock('latest');
        // @ts-ignore
        const startDate = block?.timestamp - 100;
        const endDate = startDate + 3600;
        const maxToken = BigInt(10000 * 1e18);
        await goldyToken.connect(owner).approve(ico.target, maxToken);
        await expect(ico.connect(owner).createSale(goldyToken.target, startDate, endDate, maxToken, false)).to.emit(ico, "CreateSale")
            .withArgs(0, goldyToken.target, startDate, endDate, maxToken, false);
        const totalUSDT = BigInt(10000) * await goldyPriceOracle.getGoldyUSDTPrice();
        await usdtToken.connect(owner).approve(ico.target, totalUSDT);
        await expect(ico.connect(owner).buyToken( totalUSDT, 1)).to.emit(ico, "BuyToken").withArgs(owner.address, 1, totalUSDT, BigInt(10000 * 1e18), false, "native function", "GOLDY-12355", "100");
    });

    it("add refinery connect and create sale and again create sale burn pending tokens and revert error with NGB", async function () {
        const { goldyToken, usdtToken, goldyPriceOracle, ico, owner } = await loadFixture(deployTokenFixture);
        await ico.connect(owner).addRefineryConnectDetails(Math.floor(new Date().getTime() / 1000), 12321, 100, 1000, 123343, ['GOLDY-12355'], [100]);
        const block = await ethers.provider.getBlock('latest');
        // @ts-ignore
        const startDate = block?.timestamp - 100;
        const endDate = startDate + 3600;
        const maxToken = BigInt(10000 * 1e18);
        await goldyToken.connect(owner).approve(ico.target, maxToken);
        await expect(ico.connect(owner).createSale(goldyToken.target, startDate, endDate, maxToken, false)).to.emit(ico, "CreateSale")
            .withArgs(0, goldyToken.target, startDate, endDate, maxToken, false);
        const totalUSDT = BigInt(5000) * await goldyPriceOracle.getGoldyUSDTPrice();
        await usdtToken.connect(owner).approve(ico.target, totalUSDT);
        await expect(ico.connect(owner).buyToken( totalUSDT, 1)).to.emit(ico, "BuyToken").withArgs(owner.address, 1, totalUSDT, BigInt(5000 * 1e18), false, "native function", "GOLDY-12355", "100");


        // second sale creating
        await goldyToken.connect(owner).approve(ico.target, maxToken);
        await expect(ico.connect(owner).createSale(goldyToken.target, startDate, endDate, maxToken, false)).to.be.revertedWith("NGB");
    });

    it("add refinery connect and create sale and again create sale burn pending tokens and add refinery 3 bar details with 1oz each different bar serial purchase tokens token should attach with correct bar details", async function () {
        const { goldyToken, usdtToken, goldyPriceOracle, ico, owner } = await loadFixture(deployTokenFixture);
        await ico.connect(owner).addRefineryConnectDetails(Math.floor(new Date().getTime() / 1000), 12321, 100, 1000, 123343, ['GOLDY-12355'], [100]);
        const block = await ethers.provider.getBlock('latest');
        // @ts-ignore
        const startDate = block?.timestamp - 100;
        const endDate = startDate + 3600;
        const maxToken = BigInt(10000 * 1e18);
        await goldyToken.connect(owner).approve(ico.target, maxToken);
        await expect(ico.connect(owner).createSale(goldyToken.target, startDate, endDate, maxToken, false)).to.emit(ico, "CreateSale")
            .withArgs(0, goldyToken.target, startDate, endDate, maxToken, false);
        const totalUSDT = BigInt(5000) * await goldyPriceOracle.getGoldyUSDTPrice();
        await usdtToken.connect(owner).approve(ico.target, totalUSDT);
        await expect(ico.connect(owner).buyToken( totalUSDT, 1)).to.emit(ico, "BuyToken").withArgs(owner.address, 1, totalUSDT, BigInt(5000 * 1e18), false, "native function", "GOLDY-12355", "100");


        // second sale creating
        await ico.connect(owner).addRefineryConnectDetails(Math.floor(new Date().getTime() / 1000), 12321, 100, 1000, 123343, ['GOLDY-12356', 'GOLDY-12357', 'GOLDY-12358'], [100, 50, 50]);
        await goldyToken.connect(owner).approve(ico.target, maxToken + BigInt(15000 * 1e18));
        await expect(ico.connect(owner).createSale(goldyToken.target, startDate, endDate, maxToken + BigInt(15000 * 1e18), false)).to.emit(ico, "CreateSale")
            .withArgs(1, goldyToken.target, startDate, endDate, maxToken + BigInt(15000 * 1e18));
        expect(await goldyToken.balanceOf(ico.target)).to.equal(maxToken + BigInt(15000 * 1e18));


        const total2USDT = BigInt(5000) * await goldyPriceOracle.getGoldyUSDTPrice();
        await usdtToken.connect(owner).approve(ico.target, total2USDT);
        await expect(ico.connect(owner).buyToken( total2USDT, 1)).to.emit(ico, "BuyToken").withArgs(owner.address, 1, total2USDT, BigInt(5000 * 1e18), false, "native function", "GOLDY-12355", "100");

        const total3USDT = BigInt(2000) * await goldyPriceOracle.getGoldyUSDTPrice();
        await usdtToken.connect(owner).approve(ico.target, total3USDT);
        await expect(ico.connect(owner).buyToken( total3USDT, 1)).to.emit(ico, "BuyToken").withArgs(owner.address, 1, total3USDT, BigInt(2000 * 1e18), false, "native function", "GOLDY-12356", "100");

        const total4USDT = BigInt(4000) * await goldyPriceOracle.getGoldyUSDTPrice();
        await usdtToken.connect(owner).approve(ico.target, total4USDT);
        await expect(ico.connect(owner).buyToken( total4USDT, 1)).to.emit(ico, "BuyToken").withArgs(owner.address, 1, total4USDT, BigInt(4000 * 1e18), false, "native function", "GOLDY-12356", "100");

        const total5USDT = BigInt(4000) * await goldyPriceOracle.getGoldyUSDTPrice();
        await usdtToken.connect(owner).approve(ico.target, total5USDT);
        await expect(ico.connect(owner).buyToken( total5USDT, 1)).to.emit(ico, "BuyToken").withArgs(owner.address, 1, total5USDT, BigInt(4000 * 1e18), false, "native function", "GOLDY-12356", "100");

        const total6USDT = BigInt(5000) * await goldyPriceOracle.getGoldyUSDTPrice();
        await usdtToken.connect(owner).approve(ico.target, total6USDT);
        await expect(ico.connect(owner).buyToken( total6USDT, 1)).to.emit(ico, "BuyToken").withArgs(owner.address, 1, total6USDT, BigInt(5000 * 1e18), false, "native function", "GOLDY-12357", "50");

        const total7USDT = BigInt(2000) * await goldyPriceOracle.getGoldyUSDTPrice();
        await usdtToken.connect(owner).approve(ico.target, total7USDT);
        await expect(ico.connect(owner).buyToken( total7USDT, 1)).to.emit(ico, "BuyToken").withArgs(owner.address, 1, total7USDT, BigInt(2000 * 1e18), false, "native function", "GOLDY-12358", "50");

        const total8USDT = BigInt(2000) * await goldyPriceOracle.getGoldyUSDTPrice();
        await usdtToken.connect(owner).approve(ico.target, total8USDT);
        await expect(ico.connect(owner).buyToken( total8USDT, 1)).to.emit(ico, "BuyToken").withArgs(owner.address, 1, total8USDT, BigInt(2000 * 1e18), false, "native function", "GOLDY-12358", "50");

        const total9USDT = BigInt(1000) * await goldyPriceOracle.getGoldyUSDTPrice();
        await usdtToken.connect(owner).approve(ico.target, total9USDT);
        await expect(ico.connect(owner).buyToken( total9USDT, 1)).to.emit(ico, "BuyToken").withArgs(owner.address, 1, total9USDT, BigInt(1000 * 1e18), false, "native function", "GOLDY-12358", "50");


    });

});