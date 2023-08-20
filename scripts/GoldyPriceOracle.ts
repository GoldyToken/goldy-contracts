import { ethers } from "hardhat";

async function main() {
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile
    // manually to make sure everything is compiled
    // await hre.run('compile');

    // We get the contract to deploy
    const goldyPriceOracle = await ethers.deployContract("GoldyPriceOracle", ["0x7b219F57a8e9C7303204Af681e9fA69d17ef626f", "0x44390589104C9164407A0E0562a9DBe6C24A0E05", "0x73D9c953DaaB1c829D01E1FC0bd92e28ECfB66DB", "0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7", "0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7"]);

    await goldyPriceOracle.waitForDeployment();

    console.log("goldyPriceOracle deployed to:", goldyPriceOracle.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
