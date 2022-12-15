// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

error NoDepositFoundError(bytes32 depositId);
error NotValidTimeStampError(uint256 timestamp);
error AlreadyQueuedError(bytes32 txId);
error TimestampNotInRangeError(uint256 blockTimestamp, uint256 timestamp);
error NotQueuedError(bytes32 txId);
error TimestampNotPassedError(uint256 blockTimestmap, uint256 timestamp);
error TimestampExpiredError(uint256 blockTimestamp, uint256 expiresAt);
error TxFailedError();
error NotOwner(string msg);

contract Timelock {
    // Owner of the timelock contract
    address public owner;
    string public description;

    constructor(string memory _description, address _owner) {
        description = _description;
        owner = _owner;
    }

    uint256 public constant MIN_DELAY = 10; // 10 s
    uint256 public constant MAX_DELAY = 172800; // 2 days
    uint256 public constant GRACE_PERIOD = 432000; // 5 days

    // Deposits struct/mapping
    struct Deposit {
        bytes32 depositId;
        string description;
        address from;
        address to;
        uint256 amount;
        uint256 timestamp;
        bool claimed;
    }

    // Maps an address to a list of Deposits
    mapping(address => Deposit[]) public deposits;

    // Maps an depositId to a Deposit
    mapping(bytes32 => Deposit) public depositIdToDeposit;

    // tx id => queued
    mapping(bytes32 => bool) public queued;
    mapping(bytes32 => Deposit) public queued2;

    // Events
    event DepositFundsEvent(
        address indexed _from,
        address indexed _to,
        uint256 _amount,
        uint256 _timestamp
    );
    event UpdatedDepositEvent(
        string _description,
        address indexed _from,
        address indexed _to,
        uint256 _amount,
        uint256 _timestamp
    );
    event QueuedEvent(
        bytes32 indexed txId,
        address indexed _target,
        // bytes32 _depositId,
        address _to,
        uint256 _amount,
        string _func,
        // bytes _data,
        uint256 _timestamp
    );
    event ExecutedTxEvent(
        bytes32 indexed txId,
        address indexed _target,
        address _to,
        uint256 _amount,
        // string _func,
        // bytes _data,
        uint256 _timestamp
    );
    event CancelledTxEvent(bytes32 indexed txId);

    // DepositTxId
    function getDepositTxId(
        string memory _description,
        address _from,
        address _to,
        uint256 _amount,
        uint256 _timestamp
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(_description, _from, _to, _amount, _timestamp)
            );
    }

    // TxId to Queue
    function getTxId(
        address _target, // Target Smart Contract to Execute
        bytes32 depositId, // The deposit Id (which contains all information about a deposit)
        string calldata _func // The function to run from the _target contract
    )
        public
        pure
        returns (
            // bytes calldata _data // The data to pass as function parameters
            bytes32
        )
    {
        return keccak256(abi.encode(_target, depositId, _func));
    }

    // Enables contract to receive funds
    receive() external payable {}

    // Modifier function
    modifier onlyOwner() {
        require(owner == msg.sender, "Only Owner can execute this function");
        // if (owner != msg.sender) {
        //     revert NotOwner({msg: "Only Owner can execute this function"});
        // }
        _;
    }

    modifier isValidTimestamp(uint256 _timestamp) {
        require(
            validTimestamp(_timestamp),
            "The timelock period has to be in the future"
        );
        _;
    }

    function validTimestamp(uint256 _timestamp) internal view returns (bool) {
        return (block.timestamp) < _timestamp;
    }

    function isQueued(bytes32 _txId) public view returns (bool _isQueued) {
        // return queued[_txId];
        if (queued2[_txId].to != address(0)) return true;
    }

    function removeDepositByIndex(address _depositor, uint256 _index) internal {
        if (_index >= deposits[_depositor].length) return;

        // for (uint i = _index; i<deposits[_depositor].length-1; i++){
        //     deposits[_depositor][i] = deposits[_depositor][i+1];
        // }
        // deposits[_depositor].pop();

        deposits[_depositor][_index] = deposits[_depositor][
            deposits[_depositor].length - 1
        ];
        deposits[_depositor].pop();
    }

    function reimburseUser(address _user, uint256 _amount) internal {
        (bool sent, ) = payable(_user).call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function depositFunds(
        string memory _description,
        address _to,
        uint256 _amount,
        uint256 _timestamp
    ) public payable isValidTimestamp(_timestamp) {
        require(msg.sender.balance > _amount, "Balance is low. Add more funds");
        // payable(address(this)).transfer(_amount);

        (bool sent, ) = payable(address(this)).call{value: _amount}("");
        require(sent, "Failed to send Ether");

        bytes32 depositId = getDepositTxId(
            _description,
            msg.sender,
            _to,
            _amount,
            _timestamp
        );

        deposits[msg.sender].push(
            Deposit(
                depositId,
                _description,
                msg.sender,
                _to,
                _amount,
                _timestamp,
                false
            )
        );

        // Update depositId => Deposit Mapping
        depositIdToDeposit[depositId] = Deposit(
            depositId,
            _description,
            msg.sender,
            _to,
            _amount,
            _timestamp,
            false
        );
        emit DepositFundsEvent(msg.sender, _to, _amount, _timestamp);
    }

    function getDeposits() public view returns (Deposit[] memory) {
        return deposits[msg.sender];
    }

    function getOneDeposit(bytes32 _depositTxId)
        public
        view
        returns (Deposit memory deposit, uint256 index)
    {
        // Deposit[] memory deposits[msg.sender] = deposits[msg.sender];
        for (uint256 i = 0; i < deposits[msg.sender].length; i++) {
            if (deposits[msg.sender][i].depositId == _depositTxId)
                return (deposits[msg.sender][i], i);
        }
    }

    function fetchDeposit(address _user, bytes32 _depositTxId)
        internal
        view
        returns (Deposit memory, uint256)
    {
        // Deposit[] memory deposits[_user] = deposits[_user];
        for (uint256 i = 0; i < deposits[_user].length; i++) {
            if (deposits[_user][i].depositId == _depositTxId)
                return (deposits[_user][i], i);
        }
    }

    // Update a specific Deposit
    function updateDeposit(
        bytes32 _depositId,
        string memory _description,
        address _to,
        uint256 _amount,
        uint256 _timestamp
    ) public payable isValidTimestamp(_timestamp) {
        (Deposit memory deposit, uint256 index) = getOneDeposit(_depositId);
        bytes32 depositId = getDepositTxId(
            _description,
            msg.sender,
            _to,
            _amount,
            _timestamp
        );
        require(_amount > 0, "AmountLowError");
        require(deposit.amount > 0, "NoDepositFoundError");

        if (_amount > deposit.amount) {
            // Ensure there is enough funds in the user account
            require(
                msg.sender.balance > (_amount - deposit.amount),
                "Balance low. Topup your account"
            );

            (bool sent, ) = payable(address(this)).call{
                value: _amount - deposit.amount
            }("");
            require(sent, "Failed to send Ether");
        } else if (_amount < deposit.amount) {
            reimburseUser(msg.sender, deposit.amount - _amount);
        }

        deposits[msg.sender][index] = Deposit(
            getDepositTxId(_description, msg.sender, _to, _amount, _timestamp),
            _description,
            msg.sender,
            _to,
            _amount,
            _timestamp,
            false
        );
        // Update depositId => Deposit Mapping
        require(
            depositIdToDeposit[deposit.depositId].amount > 0,
            "There is no deposit associated with this id"
        );

        // Delete old entry in the mapping
        delete depositIdToDeposit[deposit.depositId];

        // Update the mapping with new entry
        depositIdToDeposit[depositId] = Deposit(
            depositId,
            _description,
            msg.sender,
            _to,
            _amount,
            _timestamp,
            false
        );
        emit UpdatedDepositEvent(
            _description,
            msg.sender,
            _to,
            _amount,
            _timestamp
        );
    }

    function cancel(bytes32 _txId) external onlyOwner {
        // if (!queued[_txId]) {
        //     revert NotQueuedError(_txId);
        // }
        // queued[_txId] = false;
        // if (queued2[_txId].amount == 0) {
        //     revert NotQueuedError(_txId);
        // }
        require(queued2[_txId].amount > 0, "NotQueuedError");
        // queued[_txId] = false;
        delete queued2[_txId];
        emit CancelledTxEvent(_txId);
    }

    function queue(
        address _target, // Target Smart Contract to Execute
        bytes32 _depositId, // The deposit Id (which contains all information about a deposit)
        string calldata _func // The function to run from the _target contract // returns (
    )
        external
        // bytes calldata _data // The data to pass as function parameters
        onlyOwner
    // bytes32 txId
    // )
    {
        Deposit memory deposit = depositIdToDeposit[_depositId];
        bytes32 txId = getTxId(_target, _depositId, _func);
        // if (queued[txId]) {
        //     revert AlreadyQueuedError(txId);
        // }
        // if (queued2[txId].to == address(0)) {
        //     revert AlreadyQueuedError({txId: txId});
        // }
        require(queued2[txId].to == address(0), "AlreadyQueuedError");
        // ---|---------------|---------------------------|-------
        //  block       block + MIN_DELAY           block + MAX_DELAY
        if (
            deposit.timestamp < block.timestamp + MIN_DELAY ||
            deposit.timestamp > block.timestamp + MAX_DELAY
        ) {
            require(
                deposit.timestamp < block.timestamp + MIN_DELAY ||
                    deposit.timestamp > block.timestamp + MAX_DELAY,
                "TimestampNotInRangeError"
            );
            // revert TimestampNotInRangeError(block.timestamp, deposit.timestamp);
        }

        // queued[txId] = true;
        queued2[txId] = deposit;

        emit QueuedEvent(
            txId,
            _target,
            deposit.to,
            deposit.amount,
            _func,
            // _data,
            deposit.timestamp
        );
        // delete deposit;
    }

    function execute(
        address _target,
        bytes32 _depositId,
        string calldata _func
    ) external payable onlyOwner returns (bytes memory) {
        bytes32 txId = getTxId(_target, _depositId, _func);

        Deposit memory deposit = queued2[txId];
        // if (!queued[txId]) {
        //     revert NotQueuedError(txId);
        // }
        // queued[txId] = false;
        // if (queued2[txId].amount == 0) {
        //     revert NotQueuedError(txId);
        // }
        require(queued2[txId].amount > 0, "NotQueuedError");
        // ----|-------------------|-------
        //  timestamp    timestamp + grace period
        // if (block.timestamp < deposit.timestamp) {
        //     revert TimestampNotPassedError(block.timestamp, deposit.timestamp);
        // }
        // if (block.timestamp > deposit.timestamp + GRACE_PERIOD) {
        //     revert TimestampExpiredError(
        //         block.timestamp,
        //         deposit.timestamp + GRACE_PERIOD
        //     );
        // }
        require(
            queued2[txId].timestamp > block.timestamp + MIN_DELAY,
            "TimestampNotInRangeError"
        );
        require(
            queued2[txId].timestamp < block.timestamp + MAX_DELAY,
            "TimestampExpiredError"
        );

        // prepare data
        bytes memory data;
        data = abi.encodePacked(bytes4(keccak256(bytes(_func))), txId);
        // data = abi.encodeWithSignature((_func), txId);

        // call target
        (bool ok, bytes memory res) = (deposit.to).call{value: deposit.amount}(
            data
        );
        require(ok, "TxFailedError");
        // if (!ok) {
        //     revert TxFailedError();
        // }

        emit ExecutedTxEvent(
            txId,
            _target,
            deposit.to,
            deposit.amount,
            deposit.timestamp
        );
        // queued[txId] = false;
        delete queued2[txId];
        delete deposit;
        delete data;

        return res;
    }

    function claim(bytes32 _depositId) public onlyOwner {
        (Deposit memory oneDeposit, uint256 index) = getOneDeposit(_depositId);

        require(
            oneDeposit.claimed == false,
            "This deposit has been claimed already"
        );
        require(
            depositIdToDeposit[_depositId].claimed == false,
            "This deposit has been claimed already for this depositId"
        );

        deposits[oneDeposit.from][index] = Deposit(
            _depositId,
            oneDeposit.description,
            oneDeposit.from,
            oneDeposit.to,
            oneDeposit.amount,
            oneDeposit.timestamp,
            true
        );
        depositIdToDeposit[_depositId].claimed = true;

        delete oneDeposit;
    }
}
