import {
    loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";

import {ethers} from "hardhat";

describe("Token contract", function () {
    async function deployTokenFixture() {
        const [owner, addr1, addr2] = await ethers.getSigners();

        const hardhatToken = await ethers.deployContract("GoldyToken", ['GOLDY', 'GOLDY']);

        // Fixtures can return anything you consider useful for your tests
        return { hardhatToken, owner, addr1, addr2 };
    }

    it("Should assign the total supply of tokens to the owner", async function () {
        const { hardhatToken, owner } = await loadFixture(deployTokenFixture);

        const ownerBalance = await hardhatToken.balanceOf(owner.address);
        expect(await hardhatToken.totalSupply()).to.equal(ownerBalance);
    });

    it("Should transfer tokens between accounts", async function () {
        const { hardhatToken, owner, addr1, addr2 } = await loadFixture(
            deployTokenFixture
        );

        // Transfer 50 tokens from owner to addr1
        await expect(
            hardhatToken.transfer(addr1.address, 50)
        ).to.changeTokenBalances(hardhatToken, [owner, addr1], [-50, 50]);

        // Transfer 50 tokens from addr1 to addr2
        // We use .connect(signer) to send a transaction from another account
        await expect(
            hardhatToken.connect(addr1).transfer(addr2.address, 50)
        ).to.changeTokenBalances(hardhatToken, [addr1, addr2], [-50, 50]);
    });

    it("without minting role user should get revert with exception", async function () {
        const { hardhatToken, owner, addr1, addr2 } = await loadFixture(
            deployTokenFixture
        );

        // throw exception other address mint
        await expect(hardhatToken.connect(addr1).mint(BigInt(1e3 * 1e18))).to.be.revertedWith("Only Minter");
    });

    it("with minting role user should able to mint the token", async function () {
        const { hardhatToken, owner, addr1, addr2 } = await loadFixture(
            deployTokenFixture
        );
        await expect(hardhatToken.connect(addr2).mint(BigInt(1e3 * 1e18))).to.be.revertedWith("Only Minter");
        await hardhatToken.connect(owner).grantRole('0x329f6c9d87b9898860515038c2e06b2011f9cdfd29f4b8fd7a363b6534d0bb37', addr2);
        await hardhatToken.connect(addr2).mint(BigInt(1e3 * 1e18));
        expect(await hardhatToken.totalSupply()).to.equal(BigInt(1e3 + 50000) * BigInt(1e18));
        expect(await hardhatToken.balanceOf(addr2)).to.equal(BigInt(1e3 ) * BigInt(1e18));

    });

    it("burn token", async function () {
        const { hardhatToken, owner, addr1, addr2 } = await loadFixture(
            deployTokenFixture
        );
        await hardhatToken.burn(BigInt(1e3 ) * BigInt(1e18));
        expect(await hardhatToken.balanceOf(owner)).to.equal(BigInt(50000 - 1e3 ) * BigInt(1e18));
    });

});