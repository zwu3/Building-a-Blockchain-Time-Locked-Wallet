// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Timelock.sol";

contract TimelockFactory {
    Timelock timelock;
    address public owner;

    mapping(address => address[]) wallets;

    // Modifiers
    modifier onlyTimelock() {
        require(
            msg.sender == address(timelock),
            "Only Timelock can access this resource"
        );
        _;
    }

    // Events

    event WalletCreatedEvent(
        address indexed _wallet,
        address indexed _owner,
        string _description,
        uint256 _createdAt
    );

    constructor(address payable _timelockContractAddress) {
        timelock = Timelock(_timelockContractAddress);
        owner = msg.sender;
    }

    // Enables contract to receive funds
    receive() external payable {}

    function getWalletsByUser(address _user)
        internal
        view
        returns (address[] memory)
    {
        return wallets[_user];
    }

    function getWallets() public view returns (address[] memory) {
        return wallets[msg.sender];
    }

    function newTimeLockedWallet(string memory _description)
        public
        returns (address)
    {
        address wallet = address(new Timelock(_description, msg.sender));
        wallets[msg.sender].push(wallet);

        emit WalletCreatedEvent(
            wallet,
            msg.sender,
            _description,
            block.timestamp
        );
        return wallet;
    }

    function transferFunds(bytes32 _txId) external payable onlyTimelock {
        (
            bytes32 depositId,
            string memory description,
            address from,
            address to,
            uint256 amount,
            uint256 timestamp,
            bool claimed
        ) = timelock.queued2(_txId);
        (bool sent, ) = payable(to).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}
