// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {CreatorCoin} from "./CreatorCoin.sol";

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract CreatorCoinTest is Test {
    CreatorCoin creatorCoin;
    address deployer;
    address buyer;
    address seller;
    address treasury;
    IERC20 mockReserveToken;

    function setUp() public {
        deployer = address(0xBEEF);
        buyer = address(0xBAAD);
        seller = address(0xC0DE);
        treasury = address(0xF00D);
        mockReserveToken = IERC20(address(0xFA17)); // Mock address for reserve token

        vm.startPrank(deployer);
        creatorCoin = new CreatorCoin("TestCoin", "TC", address(mockReserveToken), treasury);
        vm.stopPrank();
    }

    function test_Deployment() public view {
        assertEq(creatorCoin.name(), "TestCoin", "Name should be TestCoin");
        assertEq(creatorCoin.symbol(), "TC", "Symbol should be TC");
        assertEq(creatorCoin.decimals(), 18, "Decimals should be 18");
        assertEq(creatorCoin.reserveToken(), address(mockReserveToken), "Reserve token should match");
        assertEq(creatorCoin.treasuryAddress(), treasury, "Treasury address should match");
        assertEq(creatorCoin.totalSupply(), 0, "Initial total supply should be 0");
    }

    function test_BuyTokens() public {
        vm.startPrank(buyer);
        // Simulate sending reserve token to the contract
        // In a real test with a mock ERC20, we would mint tokens to buyer and then approve/transfer
        // For this simplified test, we're assuming the reserve token transfer succeeds before calling buy.
        uint256 amountInReserveToken = 1 ether;
        uint256 boughtTokens = creatorCoin.buy(amountInReserveToken);
        vm.stopPrank();

        assertGt(boughtTokens, 0, "Should have bought some tokens");
        assertEq(creatorCoin.balanceOf(buyer), boughtTokens, "Buyer should have correct balance");
        assertEq(creatorCoin.totalSupply(), boughtTokens, "Total supply should reflect minted tokens");
    }

    function test_SellTokens() public {
        vm.startPrank(buyer);
        uint256 amountInReserveToken = 1 ether;
        creatorCoin.buy(amountInReserveToken); // Buyer buys tokens first
        vm.stopPrank();

        vm.startPrank(buyer);
        uint256 initialCreatorCoinBalance = creatorCoin.balanceOf(buyer);
        uint256 amountToSell = initialCreatorCoinBalance / 2; // Sell half of what was bought
        uint256 receivedReserveToken = creatorCoin.sell(amountToSell);
        vm.stopPrank();

        assertGt(receivedReserveToken, 0, "Should have received some reserve token");
        assertEq(creatorCoin.balanceOf(buyer), initialCreatorCoinBalance - amountToSell, "Buyer balance should decrease");
        assertEq(creatorCoin.totalSupply(), initialCreatorCoinBalance - amountToSell, "Total supply should decrease");
    }

    function test_SellTokens_RoyaltiesPaid() public {
        vm.startPrank(buyer);
        uint256 amountInReserveToken = 1 ether;
        creatorCoin.buy(amountInReserveToken);
        vm.stopPrank();

        vm.startPrank(buyer);
        uint256 initialCreatorCoinBalance = creatorCoin.balanceOf(buyer);
        uint256 amountToSell = initialCreatorCoinBalance / 2;

        vm.expectEmit(true, true, true, true, address(creatorCoin));
        emit CreatorCoin.RoyaltiesPaid(treasury, (amountToSell * creatorCoin.getCurrentPrice() * creatorCoin.ROYALTIES_PERCENTAGE) / 100);

        creatorCoin.sell(amountToSell);
        vm.stopPrank();
    }

    function test_Transfer() public {
        vm.startPrank(buyer);
        uint256 amountInReserveToken = 1 ether;
        uint256 boughtTokens = creatorCoin.buy(amountInReserveToken);
        vm.stopPrank();

        vm.startPrank(buyer);
        uint256 transferAmount = boughtTokens / 2;
        creatorCoin.transfer(seller, transferAmount);
        vm.stopPrank();

        assertEq(creatorCoin.balanceOf(buyer), boughtTokens - transferAmount, "Buyer balance should decrease after transfer");
        assertEq(creatorCoin.balanceOf(seller), transferAmount, "Seller should receive tokens");
    }

    function test_ApproveAndTransferFrom() public {
        vm.startPrank(buyer);
        uint256 amountInReserveToken = 1 ether;
        uint256 boughtTokens = creatorCoin.buy(amountInReserveToken);
        vm.stopPrank();

        vm.startPrank(buyer);
        uint256 approveAmount = boughtTokens / 2;
        creatorCoin.approve(deployer, approveAmount);
        vm.stopPrank();

        assertEq(creatorCoin.allowance(buyer, deployer), approveAmount, "Allowance should be set correctly");

        vm.startPrank(deployer);
        uint256 transferAmount = approveAmount / 2;
        creatorCoin.transferFrom(buyer, seller, transferAmount);
        vm.stopPrank();

        assertEq(creatorCoin.balanceOf(buyer), boughtTokens - transferAmount, "Buyer balance should decrease");
        assertEq(creatorCoin.balanceOf(seller), transferAmount, "Seller should receive tokens via transferFrom");
        assertEq(creatorCoin.allowance(buyer, deployer), approveAmount - transferAmount, "Allowance should decrease");
    }

    function testRevert_BuyZeroTokens() public {
        vm.startPrank(buyer);
        vm.expectRevert("Buy amount must be positive");
        creatorCoin.buy(0);
        vm.stopPrank();
    }

    function testRevert_SellZeroTokens() public {
        vm.startPrank(buyer);
        vm.expectRevert("Sell amount must be positive");
        creatorCoin.sell(0);
        vm.stopPrank();
    }

    function testRevert_SellInsufficientBalance() public {
        vm.startPrank(buyer);
        vm.expectRevert("Insufficient CreatorCoin balance to sell");
        creatorCoin.sell(1 ether); // Try to sell without buying first
        vm.stopPrank();
    }
}
