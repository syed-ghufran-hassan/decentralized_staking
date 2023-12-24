// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    mapping(address => uint256) public balances;

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 72 hours;

    bool public openForWithdraw;

    event Stake(address indexed sender, uint256 amount);
    event Withdraw(address indexed sender, uint256 amount);

    modifier notCompleted() {
        bool completed = exampleExternalContract.completed();
        require(!completed, "staking process already completed");

        // require(
        //     !exampleExternalContract.completed(),
        //     "Staking period has completed"
        // );
        _;
    }

    modifier dealineStatus() {
        uint256 timeRemaining = timeLeft();
        require(timeRemaining == 0, "Deadline is not reached");

        // if (deadlinePassed) {
        //     require(timeRemaining <= 0, "Deadline has not been passed yet");
        // } else {
        //     require(timeRemaining > 0, "Deadline is already passed");
        // }
        _;
        
    }
    modifier deadlineLeft() {
        uint256 timeRemaining = timeLeft();
        require(timeRemaining > 0, "Deadline is passed");
        _;
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )

    function stake() public payable deadlineLeft notCompleted {
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`

    function execute() public notCompleted dealineStatus {
        if (address(this).balance >= threshold)
            exampleExternalContract.complete{value: address(this).balance}();
        else {
            openForWithdraw = true;
        }
    }

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance

    function withdraw() public notCompleted {
        uint256 userBalance = balances[msg.sender];
        require(timeLeft() == 0, "Deadline not yet expired");
        require(userBalance > 0, "userBalance is 0");
        balances[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: userBalance}("");
        // (bool sent, ) = _to.call{value: userBalance}("");
        require(sent, "Failed to send to address");
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256 timeleft) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        stake();
    }
}