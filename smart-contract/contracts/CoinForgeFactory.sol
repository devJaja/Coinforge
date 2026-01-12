// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {CreatorCoin} from "./CreatorCoin.sol";
import {Events} from "./libs/Events.sol";

contract CoinForgeFactory {
    // Mapping to keep track of all deployed CreatorCoin addresses
    CreatorCoin[] public deployedCreatorCoins;

    function createCreatorCoin(
        string memory _name,
        string memory _symbol,
        address _reserveToken,
        address _treasuryAddress,
        uint256 _initialRoyaltyPercentage
    ) public returns (address) {
        CreatorCoin newCoin = new CreatorCoin(
            _name,
            _symbol,
            _reserveToken,
            _treasuryAddress,
            _initialRoyaltyPercentage
        );
        deployedCreatorCoins.push(newCoin);

        emit Events.CreatorCoinDeployed(
            address(newCoin),
            _name,
            _symbol,
            msg.sender, // The creator of the coin
            _reserveToken,
            _treasuryAddress,
            _initialRoyaltyPercentage
        );

        return address(newCoin);
    }

    function getDeployedCreatorCoins() public view returns (CreatorCoin[] memory) {
        return deployedCreatorCoins;
    }
}
