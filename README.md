#  Raffle Smart Contract

A decentralized and automated raffle (lottery) contract built using **Solidity**, **Chainlink VRF v2.5**, and **Foundry**.

---

##  Overview

This smart contract allows users to enter a raffle by paying an entrance fee. At defined intervals, Chainlink VRF is used to randomly pick a winner who receives the full balance of the contract.

---

##  Tech Stack

* [Solidity ^0.8.19](https://docs.soliditylang.org)
* [Foundry](https://book.getfoundry.sh/) (for local testing, scripting, and deployment)
* [Chainlink VRF v2.5](https://docs.chain.link/vrf/v2-5/)
* [Chainlink Automation (Upkeep-ready)](https://docs.chain.link/chainlink-automation/introduction)
* Chain ID support for **Ethereum Mainnet** **Sepolia** and **Local Anvil**

---

##  Raffle Flow

1. Users enter by sending ETH to `enterRaffle()`
2. `checkUpkeep()` ensures:

   * Enough time has passed
   * Players exist
   * Contract has balance
3. `performUpkeep()` requests randomness from Chainlink VRF
4. `fulfillRandomWords()` determines the winner and transfers the balance

---

##  Directory Structure

```
.
├── contracts/
│   └── Raffle.sol              # Main raffle contract
├── script/
│   ├── DeployRaffle.s.sol      # Deployment script
│   └── Interaction.s.sol       # VRF subscription utilities
├── test/
│   └── mocks/
│       └── LinkToken.sol       # Mock LinkToken for local testing
├── lib/                        # External libraries
├── .env                        # Environment variables
├── Makefile                    # Automation scripts
└── README.md
```

---

##  Installation

```bash
forge install
```

Or use the Makefile:

```bash
make install
```

---

##  Run Tests

```bash
forge test -vvvv
```

---

##  Deployment

###  Local (Anvil)

Start local node:

```bash
make anvil
```

Deploy:

```bash
make deploy
```

###  Sepolia

>  Ensure `.env` contains `SEPOLIA_RPC_URL`, `ACCOUNT`, `ETHERSCAN_API_KEY`, etc.

```bash
make deploy ARGS="--network sepolia"
```

---

##  Chainlink VRF Setup

###  Create Subscription

```bash
make createSubscription ARGS="--network sepolia"
```

###  Fund Subscription

```bash
make fundSubscription ARGS="--network sepolia"
```

###  Add Consumer

```bash
make addConsumer ARGS="--network sepolia"
```

---

##  Enter Raffle

```bash
make enterRaffle
```

---


##  Additional Notes

1. **Missing VRF Subscription ID**
   If you do not have a Chainlink VRF subscription ID, you can create one via the Chainlink VRF Subscription Manager [website](https://vrf.chain.link/) or by running the provided script:

   ```bash
   make createSubscription ARGS="--network sepolia"
   ```

   After obtaining a subscription ID, make sure to update it in `HelperConfig`.

2. **Using Sepolia or Mainnet**
   If you plan to interact with Sepolia or Ethereum Mainnet, update the `account` field in `HelperConfig` with your desired deployment address (wallet).

---
 

