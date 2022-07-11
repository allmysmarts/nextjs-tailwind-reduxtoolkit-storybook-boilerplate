import { HardhatUserConfig } from 'hardhat/config';

import '@typechain/hardhat';
import 'hardhat-contract-sizer';
// import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-solhint';
import '@nomiclabs/hardhat-etherscan';

import { config as dotenv } from 'dotenv';

dotenv({ path: './.env.local' });

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.6',
    settings: {
      optimizer: {
        enabled: true,
        runs: 1_000_000,
      },
    },
  },
  defaultNetwork: 'hardhat',
  paths: {
    tests: './tests',
  },
  networks: {
    hardhat: {
      // allowUnlimitedContractSize: true, // if you use this, the contract will not deploy on "real" chains
    },
    rinkeby: {
      chainId: 4,
      url: process.env.ALCHEMY_URL,
      accounts: { mnemonic: process.env.MNEMONIC },
    },
  },
  typechain: {
    outDir: './types/hardhat/',
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API,
  },
  contractSizer: {
    // runOnCompile: true,
  },
};

export default config;
