import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

import "hardhat-deploy";

import * as dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.17",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  namedAccounts: {
    deployer: {
      default: 0,
      localhost: 0,
      bnbtest: 0,
      bnb: 0,
    },
  },
  networks: {
    hardhat: {},
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    bnbtest: {
      url: process.env.BNBTest_URL,
      accounts: {
        mnemonic: process.env.BNBTest_MNEMONIC,
        count: 10,
      },
    },
    bnb: {
      url: process.env.BNB_URL,
      accounts:
        process.env.BNB_PRIVATE_KEY !== undefined
          ? [process.env.BNB_PRIVATE_KEY]
          : [],
    },
  },
};

export default config;
