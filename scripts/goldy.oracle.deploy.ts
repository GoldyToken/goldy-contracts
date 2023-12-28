import { ethers } from "hardhat";

async function main() {
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile
    // manually to make sure everything is compiled
    // await hre.run('compile');

    // We get the contract to deploy
    const goldyPriceOracle = await ethers.deployContract("GoldyPriceOracle", ["0x214eD9Da11D2fbe465a6fc601a91E62EbEc1a0D6", "0xb49f677943BC038e9857d61E7d053CaA2C1734C1", "0x5c0Ab2d9b5a7ed9f470386e82BB36A3613cDd4b5", "0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6", "0x3E7d1eAB13ad0104d2750B8863b489D65364e32D", "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419"]);

    await goldyPriceOracle.waitForDeployment();

    console.log("goldyPriceOracle deployed to:", goldyPriceOracle.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
