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
Install Truffle Framewrok
To install it, run the following command:

```
npm install -g truffle
```

Now, get the code of this project:

```
git clone https://github.com/zwu3/Building-a-Blockchain-Time-Locked-Wallet.git
cd timelock-main
```
### Truffle Console: Compile, Migrate, and Test Smart Contracts

To get started quickly, run Truffle with the built-in blockchain:

```
truffle develop
```

You should see something like this:

```
Truffle Develop started at http://127.0.0.1:9545/

Accounts:
(0) 0x2a8cd24339dccbe314e69f6c9d7dca097bbb979b
(1) 0xd017244a8dcc96c7e8e55d088edd5141098abf21
(2) 0x3a9625bf18bb9e2175dd422ec70e030fe92431fb
(3) 0x206afea815092cf89929844959f129e7673f06d6
(4) 0xd9a2e0e803e37d54893b74a0bc5cc0d9dcaf6667
(5) 0xd583f922b0dc654bd84c89057ec693aa80ea54fa
(6) 0xb070322b142e7825d187289d865845787eb41686
(7) 0x99d26633464dd86bbe58fc594245ef7c143f9735
(8) 0x16bec01c9cd845b12308619a1f4e77fffc5189e9
(9) 0x116c9eff9ede07959596fb204740547d53384995

Private Keys:
(0) 0ed7b90cbd097dc501be4c15e0b0b5b8e0afa7e31648b3f81ad79170703e3756
(1) a42dace5c2619554f8b1b4e843cdc6b2ff8b1d1907efffe97f29a1e60826ba85
(2) a61f896979dcb7ec94766a549fd5b97efc484ec9d973edf1022c9db6adf0912d
(3) 3be2478bb20c819ba0732e4a2de6de3705caf61276ab4edbd11beba74e0ea8a2
(4) e250b62c51384714483895b7334f77af5204bf815d9634d9f5c4cf887d82fdbd
(5) 65233f75e780b358985b9343acc846daf7f0205e847a4c27562f0ad199698af9
(6) 79c5dc74d0cae4ab03b8d1d42e4643f87492225be9cc951f8e858f7342f58bc7
(7) 998dcbe62e76de6f7e32a83cb5eafb7395e8dd845d03e8f9ec7a7c2557549a35
(8) bbbd71c3d5b1f878e8b5dd93c79512749739cd83202bfc0bdff68bcffb9a9954
(9) 34f181b9dd5fc0cf510f4ebf31d09a6654c9c705454f7dcaa2aa89055520613b

Mnemonic: upper deer table word local abuse forget output fury amused tennis limb

⚠️  Important ⚠️  : This mnemonic was created for you by Truffle. It is not secure.
Ensure you do not use it on production blockchains, or else you risk losing funds.
```

The mnemonic seed lets you recreate your private and public keys.

To compile the contracts, run:

```
> compile
```

This should result in something resembling the following:
(https://github.com/zwu3/Building-a-Blockchain-Time-Locked-Wallet/blob/519ce6961142cd8289c849036413add6932297a0/screenshot.png).


