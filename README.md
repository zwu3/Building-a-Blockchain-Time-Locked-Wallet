# How To Deploy a Timelock Smart

# Contract on an EVM Compatible Chain

##### The introduction of Smart Contracts to the blockchain ecosystem has opened the door

##### to the development of a new breed of software applications: Decentralized applications

##### or DApp. A Smart Contracts is a computer program that lives on a specific blockchain

##### that supports smart contracts and can be executed or enforced without human

##### interaction.

##### OpenZeppelindefined a Timelock as a “smart contractthat delays function calls of

##### another smart contract after a predetermined amount of time has passed”. Business

##### applications and other organizations could leverage this for governance or

##### administrative purposes.

##### Let's implement the following scenario, using a Timelock Smart

##### Contract:

- Bob is a very successful business man and has to stay on top of all things family,

##### business, charity, etc.

- Alice is Bob’s daughter and she studies psychology.
- Bob pays for Alice’s tuition, but wants Alice to access the funds after a specific

##### date.

- If Alice tries to withdraw before the specified date, the transaction won’t go

##### through

- Bob can change the withdrawal date or cancel the transfer within a certain period
- If Bob decides to update a deposit and the new amount to transfer is lower than

##### the original amount, Bob will be reimbursed the difference by the smart contract

- There is a MIN_DELAY that Bob has to wait before any transaction can be

##### queued

- There is a MAX_DELAY after which a transaction cannot be queued
- There is a GRACE_PERIOD during which any queued transaction can be

##### executed. Deposit.timestamp + GRACE_PERIOD should be greater than the

##### current timestamp.

##### I will briefly explain the basic development setup environment. Next, we

##### have the Timelock smart contract, a factory contract, and a test script to ensure all

##### Smart contracts execute as intended. Finally, I will show you how to deploy

##### the smart contract to a blockchain network of our choice.

### Development Environment Setup

##### Before we get started, make sure you have the following dependencies and necessary

##### software and development environment installed to follow along:Node.js,Git,

##### OpenZeppelin Contracts,Truffle

- Node.js:

##### To install Node.js, go toNodejs.org, download thecorresponding version for your

##### operating system and install it. To verify that node.js was successfully installed,

##### run the command

```
// As long as you are above version 8.0.0, you are fine
$ node -v
V16.18.
```
```
$ npm -v
8.19.
```
### Smart Contract Deployment

##### use the truffle test command which runs the truffle

##### compile and the truffle migrate commands consecutively.In the background, Truffle

##### launches a local/virtual blockchain to compile, deploy, and then test the smart contract.

##### At the end of the process, Truffle destroys the virtual network and its associated data.

##### Nothing persists once the test is complete.

##### To deploy to a local or public network that will persist our contract and its data, you

##### to explicitly use the truffle migrate command, andspecify the network we would like to

##### deploy to, with the –network flag. Truffle is smartenough to look up those

##### configurations inside the truffle-config.js file,located in the root of your project folder.
