import * as dotenv from "dotenv";

import { HardhatUserConfig } from "hardhat/config";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";
import "@nomicfoundation/hardhat-toolbox";


dotenv.config();

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

// @ts-ignore
// @ts-ignore
const config: HardhatUserConfig = {
  solidity: "0.8.19",
  networks: {
    hardhat: {
      forking: {
        url: "https://eth-mainnet.g.alchemy.com/v2/zPXme4vh-8IprCBLViHKa2Q-ByCLh-6o",
        blockNumber: 20297249,
      },
    },
    GOERLI: {
      url: process.env.GOERLI_URL || "",
      accounts:
          process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    ETHMAINNET: {
      url: process.env.ETH_URL || "",
      accounts:
          process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    BSCTestnet: {
      url: process.env.NODE_RPC_URL || "",
      accounts:
          process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
      // @ts-ignore
      networkCheckTimeout: 20000,
      skipDryRun: true,
      gas: 7000000,
      gasPrice: 10000000000,
      network_id: 97,
    },
    ganache: {
      url: "http://127.0.0.1:8545",
      accounts: [
        "e6d1ed1bc1229a32449b84633a7eae43fafeadde1cd37cb7de2f6d9f5e96e8ea",
      ],
      // @ts-ignore
      networkCheckTimeout: "20000",
      skipDryRun: true,
      gas: 7000000,
      gasPrice: 5000000000,
      network_id: 1337,
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};

export default config;
