import { ethers } from "hardhat";

async function main() {
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile
    // manually to make sure everything is compiled
    // await hre.run('compile');

    // We get the contract to deploy
    const goldyPriceOracle = await ethers.deployContract("GoldyPriceOracle", ["0xC5981F461d74c46eB4b0CF3f4Ec79f025573B0Ea", "0x1a81afB8146aeFfCFc5E50e8479e826E7D55b910", "0x91FAB41F5f3bE955963a986366edAcff1aaeaa83", "0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E", "0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E", "0x694AA1769357215DE4FAC081bf1f309aDC325306"]);

    await goldyPriceOracle.waitForDeployment();

    console.log("goldyPriceOracle deployed to:", goldyPriceOracle.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
