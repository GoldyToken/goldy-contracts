import { ethers } from "hardhat";

async function main() {
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile
    // manually to make sure everything is compiled
    // await hre.run('compile');

    // We get the contract to deploy
    const ico = await ethers.deployContract("ICO", ["0xe6576048D784F91766E8484f258530fDD2633fb3", "0x79717dBe678C0204a4Fcb7B3fAc22B1773C2cd41", "0x193773Be48cF77c0638CA315c6C905532e436c60", "0x85fBC828927dD6357692aCc9B981f1215886A028"]);

    await ico.waitForDeployment();

    console.log("ico deployed to:", ico.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
