// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

library Errors {
    // CreatorCoin Errors
    error CreatorCoin__ZeroReserveTokenAddress();
    error CreatorCoin__ZeroTreasuryAddress();
    error CreatorCoin__InvalidRoyaltyPercentage(uint256 percentage);
    error CreatorCoin__ZeroBuyAmount();
    error CreatorCoin__InsufficientReserveTokenAmount();
    error CreatorCoin__ZeroSellAmount();
    error CreatorCoin__InsufficientBalanceToSell(uint256 required, uint256 has);

    // CoinForgeFactory Errors
    // No specific errors identified yet for the factory itself,
    // as its requirements are mostly passed to CreatorCoin constructor.
}
