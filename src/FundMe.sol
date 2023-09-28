// Crowdfunding Smart Contract
// This repository contains the source code for a Crowdfunding smart contract, which serves as a decentralized funding platform.
// Users can contribute funds to support specific initiatives or projects,
/// and the contract's owner has the ability to withdraw the accumulated amount for the intended purpose.
/// The contract includes features such as fund management, withdrawal authorization, and transparency.

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19; // version

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public minAmount = 5e18; // 18 decimels
    address[] private funders;
    mapping(address funder => uint256 amountFunded) private addressToAmountFunded;
    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    // Modifiers
    modifier onlyOwner() {
        // require(msg.sender == i_owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        // receive ETH/Dollars
        require(msg.value.getConversionRate(s_priceFeed) >= minAmount, "not enough ETH");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = addressToAmountFunded[msg.sender] + msg.value;
    }

    // Func to withdraw fund from contract
    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);
        // Transfer vs call vs Send
        // payable(msg.sender).transfer(address(this).balance);
        (bool success,) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    // Func to withdraw cheaper fund from contract
    function withdrawCheaper() public onlyOwner {
        // Reading from storage is very costly than memory reading. Memory ready gas cost is like 3 only and from storage it’s 100
        uint256 fundersLength = funders.length; // reading from storage one time here.
        for (uint256 funderIndex = 0; funderIndex < fundersLength; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);
        // Transfer vs call vs Send
        // payable(msg.sender).transfer(address(this).balance);
        (bool success,) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    // receive & fallback
    // receive and fallback don't need function keyword and are special functions. Construct too
    // If data is passed in a trx receive func will be called and if not fallback will be called

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function getPriceFeedVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    /**
     * view / pure functions (getters)
     */
    function getAddressToAmountFunded(address fundingAddress) external view returns (uint256) {
        return addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
