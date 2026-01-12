// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

library Events {
    // CreatorCoin Events
    event TokensPurchased(address indexed buyer, uint256 amountInReserveToken, uint256 amountOfCreatorCoin);
    event TokensSold(address indexed seller, uint256 amountInCreatorCoin, uint256 amountOutReserveToken);
    event RoyaltiesPaid(address indexed beneficiary, uint256 amount);
    event RoyaltyRateUpdated(uint256 oldRate, uint256 newRate);

    // CoinForgeFactory Events
    event CreatorCoinDeployed(address indexed creatorCoinAddress, string name, string symbol, address indexed creator, address reserveToken, address treasuryAddress, uint256 initialRoyaltyPercentage);
}
