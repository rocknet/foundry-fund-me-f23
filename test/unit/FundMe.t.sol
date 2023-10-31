// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    uint8 private constant PRICE_FEED_VERSION = 4;
    uint64 private constant SEND_VALUE = 0.1 ether;
    uint64 private constant STARTING_BALANCE = 1 ether;
    uint64 private constant MINIMUM_USD = 5e18;

    FundMe private fundMe;
    address private USER = makeAddr("user");

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), MINIMUM_USD);
    }

    function testOwnerIsMessageSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsCorrect() public {
        assertEq(fundMe.getVersion(), PRICE_FEED_VERSION);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public funded {
        assertEq(fundMe.getAddressToAmountFunded(USER), SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        assertEq(fundMe.getFunder(0), USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunders() public funded {
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        assertEq(
            fundMe.getOwner().balance,
            startingOwnerBalance + startingFundMeBalance
        );
        assertEq(address(fundMe).balance, 0);
    }

    function testWithdrawWithMultipleFunders() public funded {
        uint8 numberOfFunders = 10;
        for (uint8 i = 1; i < numberOfFunders; i++) {
            hoax(address(uint160(i)), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        assertEq(
            fundMe.getOwner().balance,
            startingOwnerBalance + startingFundMeBalance
        );
        assertEq(address(fundMe).balance, 0);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }
}
