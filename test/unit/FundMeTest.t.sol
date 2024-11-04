//SPDX-license-Identifier:MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol"; 
/* essential to import for runing tests
console is used to print from the tests
*/
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
contract FundMeTest is Test{
    FundMe fundMe;

    address USER = makeAddr('user'); //used to depict whos sending the contract
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;
    //In all tests this is the first function, always runs first
    function setUp() external{
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }
    
    //Test the contract present in the setUp function
    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18); //check if this fn is = 5e18
    }

   /* function testOnwerIsMsgSender() public{
        // console.log(fundMe.i_owner()); //owner of fundme is fundmetest not uscfor
       // console.log(msg.sender);
        // assertEq(fundMe.i_owner(), msg.sender);
        assertEq(fundMe.getOwner(), address(this));
    }
    */

/* function testPriceFeedVersionIsOkay() public{
    uint256 version = fundMe.getVersion();
    assertEq(version, 4);
    }
  */

    function sendFundFailWithoutEnoughEth() public{
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public{ //check if valiables are getting updated 's_' var
        vm.prank(USER); //The next TX will be sent by USER
        fundMe.fund{value : SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public{
        vm.prank(USER); //this and next line are used to fund
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded(){
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public{
        vm.prank(USER); //this and next line are used to fund
        fundMe.fund{value: SEND_VALUE}();

        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();

    }

    function testWithdrawWithASingleFunder() public funded{
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endigFundMeBalance = address(fundMe).balance;
        assertEq(endigFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded{
        //Arrange
        uint160 numberOfFunders = 10; //if u want to generate addresses using numbers those have to be uint160
        uint160 startingFunderIndex = 1;
        for(uint160 i= startingFunderIndex; i< numberOfFunders;i++){
            hoax(address(i), SEND_VALUE); //does vm.prank and vm.deal combined
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
       // uint256 gasStart = gasLeft(); //how much gas left before the next lines are executed

        vm.txGasPrice(GAS_PRICE);
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

       // uint256 gasEnd = gasLeft();

        //uint256 gasUsed = (gasStart - gasEnd)*tx.gasprice;

        //assert
        assert(address(fundMe).balance ==0);
        assert(startingFundMeBalance+startingOwnerBalance == 
            fundMe.getOwner().balance);
    }
}
