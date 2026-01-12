// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {CoinForgeFactory} from "../contracts/CoinForgeFactory.sol";
import {CreatorCoin} from "../contracts/CreatorCoin.sol";

contract CoinForgeFactoryTest is Test {
    CoinForgeFactory factory;
    address deployer;
    address alice;
    address bob;

    function setUp() public {
        deployer = address(0xBEEF);
        alice = address(0xA11CE);
        bob = address(0xB0B);

        vm.startPrank(deployer);
        factory = new CoinForgeFactory();
        vm.stopPrank();
    }

    function test_CreateCreatorCoin() public {
        string memory name = "AliceCoin";
        string memory symbol = "ALICE";
        address reserveToken = address(0x01); // Mock reserve token address
        address treasuryAddress = alice; // Alice's address as treasury

        vm.startPrank(alice);
        vm.expectEmit(true, true, true, true, address(factory));
        emit CoinForgeFactory.CreatorCoinDeployed(
            address(0), // We don't know the exact address yet, check for any address
            name,
            symbol,
            alice,
            reserveToken,
            treasuryAddress
        );
        address newCoinAddress = factory.createCreatorCoin(name, symbol, reserveToken, treasuryAddress);
        vm.stopPrank();

        assertNotEq(newCoinAddress, address(0), "New coin address should not be zero");

        // Verify the deployed coin properties
        CreatorCoin newCoin = CreatorCoin(newCoinAddress);
        assertEq(newCoin.name(), name, "Deployed coin name mismatch");
        assertEq(newCoin.symbol(), symbol, "Deployed coin symbol mismatch");
        assertEq(newCoin.reserveToken(), reserveToken, "Deployed coin reserve token mismatch");
        assertEq(newCoin.treasuryAddress(), treasuryAddress, "Deployed coin treasury address mismatch");

        // Verify it's added to the list of deployed coins
        CreatorCoin[] memory deployedCoins = factory.getDeployedCreatorCoins();
        assertEq(deployedCoins.length, 1, "Should have one deployed coin");
        assertEq(address(deployedCoins[0]), newCoinAddress, "Deployed coin address in list mismatch");
    }

    function test_MultipleCreatorCoins() public {
        string memory name1 = "CoinOne";
        string memory symbol1 = "COIN1";
        address reserveToken1 = address(0x01);
        address treasuryAddress1 = alice;

        string memory name2 = "CoinTwo";
        string memory symbol2 = "COIN2";
        address reserveToken2 = address(0x02);
        address treasuryAddress2 = bob;

        vm.startPrank(alice);
        factory.createCreatorCoin(name1, symbol1, reserveToken1, treasuryAddress1);
        vm.stopPrank();

        vm.startPrank(bob);
        factory.createCreatorCoin(name2, symbol2, reserveToken2, treasuryAddress2);
        vm.stopPrank();

        CreatorCoin[] memory deployedCoins = factory.getDeployedCreatorCoins();
        assertEq(deployedCoins.length, 2, "Should have two deployed coins");

        // Verify first coin
        CreatorCoin coin1 = deployedCoins[0];
        assertEq(coin1.name(), name1);
        assertEq(coin1.symbol(), symbol1);

        // Verify second coin
        CreatorCoin coin2 = deployedCoins[1];
        assertEq(coin2.name(), name2);
        assertEq(coin2.symbol(), symbol2);
    }
}
