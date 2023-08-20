import { ethers } from "hardhat";

async function main() {
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile
    // manually to make sure everything is compiled
    // await hre.run('compile');

    // We get the contract to deploy
    const ico = await ethers.deployContract("ICO", ["0x4E36C37F2Fae8eEE7aD45c1124872E025Ac2F08b", "0x79717dBe678C0204a4Fcb7B3fAc22B1773C2cd41"]);

    await ico.waitForDeployment();

    console.log("ico deployed to:", ico.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
