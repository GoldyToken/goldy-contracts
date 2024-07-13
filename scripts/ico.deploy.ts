import { ethers } from "hardhat";

async function main() {
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile
    // manually to make sure everything is compiled
    // await hre.run('compile');

    // We get the contract to deploy
    const ico = await ethers.deployContract("ICO", [String(process.env.PRICE_ORACLE), String(process.env.USDC_TOKEN), String(process.env.USDT_TOKEN), String(process.env.EUROC_TOKEN), String(process.env.REFINERY_ADDRESS)]);

    await ico.waitForDeployment();

    console.log("ico deployed to:", ico.target);

    // await ico.addRefineryConnectDetails(1714130642, 12321, 100, 1000, 123343, ['etete'], [100]);
    // console.log("Refinery Details Added");


}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
