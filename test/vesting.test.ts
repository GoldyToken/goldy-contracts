import {
    loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";

import {ethers} from "hardhat";

describe("Vesting contract", function () {

    async function deployTokenFixture() {
        const [owner, addr1, addr2] = await ethers.getSigners();

        const vesting = await ethers.deployContract("Vesting");
        const goldyToken = await ethers.deployContract("GoldyToken", ['GOLDY', 'GOLDY']);

        // Fixtures can return anything you consider useful for your tests
        return { vesting, goldyToken, owner, addr1, addr2 };
    }

    it("should create a vesting pool and emit LockToken event", async function () {

        const { vesting, goldyToken, owner, addr1 } = await loadFixture(deployTokenFixture);
        const amount = BigInt(1000 * 1e18); // Specify the amount
        const period = 30 * 24 * 60 * 60; // 30 days
        const cliff = Math.floor(new Date().getTime() / 1000) + 7 * 24 * 60 * 60; // 7 days from now
        const periodBP = 5000; // 50%
        const firstReleaseInBP = 2000; // 20%

        await goldyToken.transfer(addr1.address, amount);
        await goldyToken.connect(addr1).approve(vesting.target, amount);

        await expect(vesting.connect(addr1).create(period, cliff, periodBP, firstReleaseInBP, amount, addr1.address, goldyToken.target))
            .to.emit(vesting, "LockToken")
            .withArgs(period, cliff, periodBP, firstReleaseInBP, amount, addr1.address, goldyToken.target);

        const vestingPoolId = await vesting.vestingIds(addr1.address, 0);
        const vestingPool = await vesting.vestingPools(vestingPoolId);

        expect(vestingPool.amount).to.equal(amount);
        expect(vestingPool.user).to.equal(addr1.address);
        expect(vestingPool.token).to.equal(goldyToken.target);
    });

    it("should calculate available tokens to withdraw correctly", async function () {
        const { vesting, goldyToken, addr1 } = await loadFixture(deployTokenFixture);
        const amount = BigInt(1000 * 1e18); // Specify the amount
        const period = 30 * 24 * 60 * 60; // 30 days
        const cliff = Math.floor(new Date().getTime() / 1000) + 7 * 24 * 60 * 60; // 7 days from now
        const periodBP = 5000; // 50%
        const firstReleaseInBP = 2000; // 20%

        await goldyToken.transfer(addr1.address, amount);
        await goldyToken.connect(addr1).approve(vesting.target, amount);

        await vesting.connect(addr1).create(period, cliff, periodBP, firstReleaseInBP, amount, addr1.address, goldyToken.target);

        const vestingPoolId = await vesting.vestingIds(addr1.address, 0);
        const vestingPool = await vesting.vestingPools(vestingPoolId);

        const vestingPoolObject = {
            period: Number(vestingPool[0]),
            cliff: Number(vestingPool[1]),
            periodBP: Number(vestingPool[2]),
            firstReleaseInBP: Number(vestingPool[3]),
            releasedBP: Number(vestingPool[4]),
            amount: Number(vestingPool[5]),
            user: vestingPool[6],
            token: vestingPool[7]
        };

        console.log("vesting object =>", vestingPoolObject);
        // Move time to just after the cliff
        await ethers.provider.send("evm_increaseTime", [cliff + 1]);
        await ethers.provider.send("evm_mine", []);

       await vesting.connect(addr1).withdraw(0);
    });
});
