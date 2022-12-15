let Timelock = artifacts.require('./Timelock');
let TimelockFactory = artifacts.require('./TimelockFactory');
let ethToDeposit = web3.utils.toWei("1", "ether");
let creator;
let bob;
let Alice;
let timelockContract;
let timelockFactoryContract;
let timestamp;
let depositId;
let deposit;
let timelockedWallets;
let timelockedWalletInstance;


function getABIParameter(_contractArtifact, _parameterType, _parameterName){
    const abi = _contractArtifact.abi;
    const filtered = abi.filter((interface) => interface.type == _parameterType && interface.name == _parameterName)
    return filtered[0];
}

contract('Timelock Factory', async (accounts, network, deployer) => {

    before("Deploy Contracts", async function() {
        web3Accounts = await web3.eth.getAccounts()
        creator = accounts[0] || web3Accounts[0];
        bob = accounts[1] || web3Accounts[1];
        alice = accounts[9] || web3Accounts[9];
        
        timelockContract = await Timelock.deployed();
        timelockFactoryContract = await TimelockFactory.deployed();
        // timestamp = new Date("2021-05-14").getTime() / 1000
        timestamp = Date.parse("Sat Nov 19 2022 10:00:50 GMT-0800 (Pacific Standard Time)") / 1000
        
    });

    it('Initializes the contract with the correct values', async function() {

        // console.log("Alice balance", await web3.utils.fromWei(await web3.eth.getBalance(alice)))
        assert.notEqual(await timelockFactoryContract.owner(), 0x0, 'The Owner of the smart contract was set')
        assert.equal(await timelockFactoryContract.owner(), creator, 'Contract not owned by Timelock')
        assert.notEqual(await timelockFactoryContract.address, 0x0, 'The smart contract address was set')
    });

    it('Creates a new Timelocked Wallet Instance', async function() {
        await timelockFactoryContract.newTimeLockedWallet("Bob's Family Funds", {
            from: bob, 
            // gasPrice: '20000000000', // default gas price in wei, 20 gwei in this case,
            // transactionConfirmationBlocks: 3
        })
        // console.log("timelock", timelock)
        timelockedWallets = await timelockFactoryContract.getWallets({from:bob});
        // console.log(timelockedWallets)
        // timelockFactoryContract = await TimelockFactory.deployed();

        timelockedWalletInstance = await new web3.eth.Contract(timelockContract.abi, timelockedWallets[0]);
        assert.equal(await timelockedWalletInstance.methods.owner().call(), bob, "The owner of the timelocked instance was not set properly")
        assert.equal(await timelockedWalletInstance.methods.description().call(), "Bob's Family Funds", "The description was not set properly")
    })
    it('Funds Smart Contracts Accounts', async function(){
 
        try {
            
            const receipt = await web3.eth.sendTransaction({
                from: String(creator),
                to:  String(timelockedWallets[0]),
                value:  String(await web3.utils.toWei("5", "ether")),
            })
            // console.log(await web3.eth.getBalance(timelockedWallets[0]))
            
            assert.equal(await web3.eth.getBalance(timelockedWallets[0]), await web3.utils.toWei("5", "ether"), "Timelocked Wallet Not funded properly");
        } catch (error) {
            console.log(error)
        }
    })

    it('Deposits funds', async function() {
        try {
            await timelockedWalletInstance.methods.depositFunds("Tuition Fees 2022", alice, ethToDeposit, (timestamp)).send({from:bob, value:ethToDeposit, gas:'2100000'})
            
            depositId = await timelockedWalletInstance.methods.getDepositTxId("Tuition Fees 2022", bob,alice, ethToDeposit, (timestamp),).call({from:bob})
            const res = await (timelockedWalletInstance.methods.getOneDeposit(depositId)).call({from:bob})
            deposit = res[0]
        } catch (error) {
            console.log(error)
        }
    })

    it('Queues a Withdrawal transaction after the deposit', async function() {
        // depositId = await timelockedWalletInstance.getDepositTxId("New Description", bob,alice, await web3.utils.toWei("0.01", "ether"), (timestamp),{from:bob})
        const abiEntry = await getABIParameter(TimelockFactory, "function", "transferFunds")
        // console.log(abiEntry)
        try {
            const txId = await timelockedWalletInstance.methods.getTxId(
                timelockFactoryContract.address, // Target Smart Contract to Execute
                 depositId, // The deposit Id (which contains all information about a deposit)
                 abiEntry.name + "(bytes32)", // The function to run from the _target contract
                //   [], // Data to pass as argument to the function
                   
            ).call()
            const contractOwner = await timelockedWalletInstance.methods.owner().call();
            const receipt = await timelockedWalletInstance.methods.queue(await timelockFactoryContract.address, depositId, abiEntry.name + "(bytes32)").send({from: bob, gas: "2100000"});
            
            // console.log("receipt", receipt.events.QueuedEvent.returnValues)
            assert.equal(receipt.events.QueuedEvent.event, "QueuedEvent", "The QueuedEvent was not fired")
            assert.equal(Number(receipt.events.QueuedEvent.returnValues._amount), ethToDeposit, "The amount is incorrect")
            assert.equal(await timelockedWalletInstance.methods.isQueued(txId).call(), true, "Transaction was not properly queued")
            
            
        } catch (error) {
            console.log(error)
        }
        
    })
    
    it('Executes the Queued Transaction', async function() {
        const abiEntry = await getABIParameter(TimelockFactory, "function", "transferFunds")
        const contractOwner = await timelockedWalletInstance.methods.owner().call();

        const userBalanceBeforeExecution = await web3.utils.fromWei(await web3.eth.getBalance(alice))
        const calculated = Number(await web3.utils.fromWei((ethToDeposit))) + Number(userBalanceBeforeExecution)
        // console.log("calculated", calculated)
        try {
            // Execute the transaction
            const receiptExec = await timelockedWalletInstance.methods.execute(
                timelockFactoryContract.address, 
                depositId, 
                abiEntry.name + "(bytes32)",
                
            ).send({from: bob})
            // console.log(receiptExec)

            const res = await timelockedWalletInstance.methods.getOneDeposit(depositId).call({from:bob});
            // console.log(res[0])
            
            assert.equal(Number(await web3.utils.fromWei(await web3.eth.getBalance(alice))).toFixed(3), calculated.toFixed(3), "The transfer of funds was not successful")
            
        } catch (error) {
            console.log(error)
        }
    })
    
    it('Updates the Claimed field of the Deposit to TRUE', async function(){
        await timelockedWalletInstance.methods.claim(depositId).send({from:bob});
        const oneDeposit = await timelockedWalletInstance.methods.getOneDeposit(depositId).call({from:bob});
        const depositIdToDepositMapping = await timelockedWalletInstance.methods.depositIdToDeposit(depositId).call({from:bob});
        // console.log(oneDeposit[0])
        // console.log(depositIdToDepositMapping)
        assert.equal(oneDeposit[0].claimed, true, "The Deposit was not updated successfully")
        assert.equal(depositIdToDepositMapping.claimed, true, "The depositIdToDepositMapping was not updated successfully")
    })


})