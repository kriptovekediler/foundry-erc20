//SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {OurToken} from "../src/OurToken.sol";

interface MintableToken {
    function mint(address, uint256) external;
}

contract OurTokenTest is Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");

    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        vm.prank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);
    }

    function testBobBalance() public {
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE);
    }

    function testAllowancesWorks() public {
        uint256 initialAllowance = 1000;

        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        uint256 transferAmount = 500;

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);

        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
    }

    function testInitialSupply() public {
        assertEq(ourToken.totalSupply(), deployer.INITIAL_SUPPLY());
    }

    function testUsersCantMint() public {
        vm.expectRevert();
        MintableToken(address(ourToken)).mint(address(this), 1);
    }

    function testTransfer() public {
        uint256 amount = 100;
        address recipient = address(0x123);

        ourToken.transfer(recipient, amount);

        assertEq(ourToken.balanceOf(recipient), amount);
        assertEq(
            ourToken.balanceOf(address(this)),
            deployer.INITIAL_SUPPLY() - amount
        );
    }

    function testTransferFrom() public {
        uint256 amount = 50;
        address spender = address(0x456);
        address recipient = address(0x789);

        ourToken.approve(spender, amount);
        ourToken.transferFrom(address(this), recipient, amount);

        assertEq(ourToken.balanceOf(recipient), amount);
        assertEq(
            ourToken.balanceOf(address(this)),
            deployer.INITIAL_SUPPLY() - amount
        );
        assertEq(ourToken.allowance(address(this), spender), 0);
    }

    function testIncreaseDecreaseAllowance() public {
        address spender = address(0xabc);
        uint256 initialAllowance = 100;
        uint256 increaseAmount = 50;
        uint256 decreaseAmount = 30;

        ourToken.approve(spender, initialAllowance);

        ourToken.increaseAllowance(spender, increaseAmount);
        assertEq(
            ourToken.allowance(address(this), spender),
            initialAllowance + increaseAmount
        );

        ourToken.decreaseAllowance(spender, decreaseAmount);
        assertEq(
            ourToken.allowance(address(this), spender),
            initialAllowance + increaseAmount - decreaseAmount
        );
    }

    function testBurn() public {
        uint256 burnAmount = 20;

        ourToken.burn(burnAmount);
        assertEq(
            ourToken.totalSupply(),
            deployer.INITIAL_SUPPLY() - burnAmount
        );
    }
}
