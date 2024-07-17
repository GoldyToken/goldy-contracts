# Goldy Token

Goldy Token is a physically gold-backed token implemented using the Hardhat framework.

## Test and Deployment

### Running Tests

To run tests, use the following command:

```bash
npx hardhat test
````

```bash
npx hardhat run scripts/deploy.js --network <network_name>
```

### Contract Deployment

To deploy smart contract, use the following command:

```bash
npx hardhat run scripts/deploy.js --network <network_name>
```


### Test Cases Hardhat Fork

to do forking need to adjust configuration in hardhat.config.ts

```bash
module.exports = {
  // other configurations
  networks: {
    // other networks
    hardhat: {
      forking: {
        url: "<mainnet_provider_url>",
        blockNumber: <block_number_to_fork>,
      },
    },
  },
};

```