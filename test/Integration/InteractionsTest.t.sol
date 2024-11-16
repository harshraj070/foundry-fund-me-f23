// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";
import {FundMe} from "../../src/FundMe.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";

contract InteractionsTest is ZkSyncChainChecker, StdCheats, Test {
    FundMe public fundMe;
    HelperConfig public helperConfig;

    uint256 public constant SEND_VALUE = 0.1 ether; // Enough value to test funding.
    uint256 public constant STARTING_USER_BALANCE = 10 ether; // Initial user balance.
    uint256 public constant GAS_PRICE = 1 gwei; // Example gas price.

    address public constant USER = address(1); // Simulated user address.

    function setUp() external skipZkSync {
        if (!isZkSyncChain()) {
            // Deploy contract on non-ZkSync chains.
            DeployFundMe deployer = new DeployFundMe();
            (fundMe, helperConfig) = deployer.deployFundMe();
        } else {
            // Fallback deployment for ZkSync chains.
            helperConfig = new HelperConfig();
            fundMe = new FundMe(helperConfig.getConfigByChainId(block.chainid).priceFeed);
        }

        // Provide initial balance to USER.
        vm.deal(USER, STARTING_USER_BALANCE);
    }

    function testUserCanFundAndOwnerWithdraw() public skipZkSync {
        uint256 preUserBalance = USER.balance;
        uint256 preOwnerBalance = fundMe.getOwner().balance;

        // Simulate funding from USER.
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        // Ensure the contract balance is updated.
        assertEq(address(fundMe).balance, SEND_VALUE);

        // Withdraw funds from the contract.
        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        uint256 postUserBalance = USER.balance;
        uint256 postOwnerBalance = fundMe.getOwner().balance;

        // Assertions to validate functionality.
        assertEq(address(fundMe).balance, 0); // Contract balance should be zero.
        assertEq(postOwnerBalance, preOwnerBalance + SEND_VALUE); // Owner receives funds.
        assertLt(postUserBalance, preUserBalance); // User spent gas for funding.
    }
}
