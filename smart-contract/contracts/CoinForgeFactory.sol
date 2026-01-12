// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {CreatorCoin} from "./CreatorCoin.sol";

contract CoinForgeFactory {
    // Event emitted when a new CreatorCoin is deployed
    event CreatorCoinDeployed(
        address indexed creatorCoinAddress,
        string name,
        string symbol,
        address indexed creator,
        address reserveToken,
        address treasuryAddress
    );

    // Mapping to keep track of all deployed CreatorCoin addresses
    CreatorCoin[] public deployedCreatorCoins;

    function createCreatorCoin(
        string memory _name,
        string memory _symbol,
        address _reserveToken,
        address _treasuryAddress
    ) public returns (address) {
        CreatorCoin newCoin = new CreatorCoin(_name, _symbol, _reserveToken, _treasuryAddress);
        deployedCreatorCoins.push(newCoin);

        emit CreatorCoinDeployed(
            address(newCoin),
            _name,
            _symbol,
            msg.sender, // The creator of the coin
            _reserveToken,
            _treasuryAddress
        );

        return address(newCoin);
    }

    function getDeployedCreatorCoins() public view returns (CreatorCoin[] memory) {
        return deployedCreatorCoins;
    }
}
