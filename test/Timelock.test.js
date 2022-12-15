let Timelock = artifacts.require('./Timelock');
let TimelockFactory = artifacts.require('./TimelockFactory');
let ethToDeposit = web3.utils.toWei("0.05", "ether");
let creator;
let owner;
let timelockContract;
let timelockFactoryContract;
let timestamp;
let depositReceipt;
let depositId;
let deposit;


function getABIParameter(_contractArtifact, _parameterType, _parameterName){
    const abi = _contractArtifact.abi;
    const filtered = abi.filter((interface) => interface.type == _parameterType && interface.name == _parameterName)
    return filtered[0];
}

contract('Timelock', async function(accounts) {

    before("Deploy Contracts", async function() {
        creator = accounts[0];
        owner = accounts[1];
        other = accounts[2];
        timelockContract = await Timelock.deployed();
        timelockFactoryContract = await TimelockFactory.deployed();

        timestamp = Date.parse("Sat Nov 19 2022 10:00:50 GMT-0800 (Pacific Standard Time)") / 1000
    });

    it('Initializes the contract with the correct values', async function() {
        assert.equal(await timelockContract.description(), "Family Timelock Funds", 'The Timelock description was not set')
        assert.notEqual(await timelockContract.owner(), 0x0, 'The Owner of the smart contract was set')
        assert.notEqual(await timelockContract.address, 0x0, 'The smart contract address was set')
    });

    it('Funds Smart Contracts Accounts', async function(){
        try {
            await web3.eth.sendTransaction({
                from: (creator),
                to:  (timelockContract.address),
                value:  (await web3.utils.toWei("5", "ether")),
            })
            assert.equal(await web3.eth.getBalance(timelockContract.address), await web3.utils.toWei("5", "ether"), "Contract Not funded properly")
            
        } catch (error) {
            console.log(error)
        }
    })

    it('Ensures the timestamp is in the future', async function() {
        try {
            
            let receipt = await timelockContract.depositFunds.call("Tuition Fees 2022", owner, ethToDeposit, Date.parse("2022-05-14") / 1000, {from:creator, value:ethToDeposit})
            assert.notEqual(receipt, true);
        } catch (error) {
            assert(error.message.indexOf('revert') >= 0, 'Timestamp is in the past. Should be in the future');
            return true;
        }
    })

    it('Deposits funds', async function() {

        depositReceipt = await timelockContract.depositFunds("Tuition Fees 2022", owner, ethToDeposit, (timestamp), {from:creator, value:ethToDeposit})
        depositReceipt = await timelockContract.depositFunds("Tuition Fees 2023", owner, ethToDeposit, (timestamp), {from:creator, value:ethToDeposit})
        depositId = await timelockContract.getDepositTxId("Tuition Fees 2022", creator,owner, ethToDeposit, (timestamp),{from:creator})
        deposit = (await timelockContract.getOneDeposit(depositId, {from:creator}))
        let deposits = await timelockContract.getDeposits({from:creator})
    })

    it('Ensures that the deposit was broadcasted to the network', async function() {
        
        let events = depositReceipt.logs.filter((log) => log.event == "DepositFundsEvent");
        if (events.length > 0) {
            assert.equal(events[0].args._from, creator)
            assert.equal(events[0].args._to, owner)
            assert.equal(Number(events[0].args._amount), ethToDeposit)
            assert.equal(Number(events[0].args._timestamp), timestamp)
        } else{
            assert(false)
        }
    })

    it('Ensures that Deposit is updated properly', async function() {
        
        try {
            let receipt = await timelockContract.updateDeposit(depositId, "New Description", owner, await web3.utils.toWei("0.01", "ether"), (timestamp),{from:creator})
            // console.log("receipt", receipt)

            let deposits = await timelockContract.getDeposits({from:creator})
            // console.log(deposits.length)

            // Assert UpdatedDepositEvent() was logged
            // Assert Struct was updated as expected
            
        } catch (error) {
            console.log(error)
        }
    })

    it('Queues a Withdrawal transaction after the deposit', async function() {
        depositId = await timelockContract.getDepositTxId("New Description", creator,owner, await web3.utils.toWei("0.01", "ether"), (timestamp),{from:creator})
        const abiEntry = await getABIParameter(TimelockFactory, "function", "transferFunds")
        // console.log(abiEntry)
        try {
            const txId = await timelockContract.getTxId(
                timelockFactoryContract.address, // Target Smart Contract to Execute
                 depositId, // The deposit Id (which contains all information about a deposit)
                 abiEntry.name + "(bytes32)", // The function to run from the _target contract
                //   [], // Data to pass as argument to the function
                  {from:creator} 
            )
            let receipt = await timelockContract.queue(timelockFactoryContract.address, depositId, abiEntry.name + "(bytes32)", {from:creator})
            // console.log(receipt.logs)
            assert.equal(receipt.logs[0].event, "QueuedEvent", "The QueuedEvent was not fired")
            assert.equal(Number(receipt.logs[0].args._amount), await web3.utils.toWei("0.01", "ether"), "The amount is incorrect")
            assert.equal(await timelockContract.isQueued(txId), true, "Transaction was not properly queued")

        } catch (error) {
            console.log(error)
        }

    })

    it('Cancels an already queued transaction', async function() {
        const abiEntry = await getABIParameter(TimelockFactory, "function", "transferFunds")
        const txId = await timelockContract.getTxId(
            timelockFactoryContract.address, // Target Smart Contract to Execute
             depositId, // The deposit Id (which contains all information about a deposit)
             abiEntry.name + "(bytes32)", // The function to run from the _target contract
            //   [], // Data to pass as argument to the function
              {from:creator} 
        )
        await timelockContract.cancel(txId, {from:creator})
        assert.equal(await timelockContract.isQueued(txId), false, "Transaction was not properly cancelled")
    })
    it('Successfully Fails at Cancelling an already cancelled transaction', async function() {
        const abiEntry = await getABIParameter(TimelockFactory, "function", "transferFunds")
        try {
            const txId = await timelockContract.getTxId(
                timelockFactoryContract.address, // Target Smart Contract to Execute
                 depositId, // The deposit Id (which contains all information about a deposit)
                 abiEntry.name + "(bytes32)", // The function to run from the _target contract
                //   [], // Data to pass as argument to the function
                  {from:creator} 
            )
            const receipt = await timelockContract.cancel(txId, {from:creator})
            assert.notEqual(receipt, true, "Transaction was properly cancelled")
            
        } catch (error) {
            assert(error.message.indexOf('revert') >= 0, 'Transaction has already been cancelled');
            return true;
        }
    })


})