// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

/*//////////////////////////////////////////////////////////////
                            IMPORTS
//////////////////////////////////////////////////////////////*/

import {CreatorCoin} from "./CreatorCoin.sol";
import {Events} from "./libs/Events.sol";

/*//////////////////////////////////////////////////////////////
                         CONTRACT METADATA
//////////////////////////////////////////////////////////////*/

/// @title CoinForgeFactory
/// @author CoinForge Team
/// @notice This contract is responsible for deploying new CreatorCoin contracts.
/// It acts as a factory for creating and managing CreatorCoin instances.

contract CoinForgeFactory {
    /*//////////////////////////////////////////////////////////////
                               STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev An array to keep track of all deployed CreatorCoin contract addresses.
    /// This allows for easy retrieval and auditing of all coins created by the factory.
    // Mapping to keep track of all deployed CreatorCoin addresses
    CreatorCoin[] public deployedCreatorCoins;

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates and deploys a new CreatorCoin contract.
    /// @dev This function instantiates a new CreatorCoin with the provided parameters,
    /// stores its address, and emits an event.
    /// @param _name The name of the new CreatorCoin.
    /// @param _symbol The symbol of the new CreatorCoin.
    /// @param _reserveToken The address of the ERC-20 token used as a reserve for bonding curve.
    /// @param _treasuryAddress The address designated to receive a portion of the reserve.
    /// @param _initialRoyaltyPercentage The initial percentage of royalties for the creator.
    /// @return The address of the newly deployed CreatorCoin contract.u
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

    /*//////////////////////////////////////////////////////////////
                           VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns an array of all CreatorCoin contracts deployed by this factory.
    /// @dev This function provides a way to retrieve all CreatorCoin instances
    /// that have been created through this factory.
    /// @return An array containing all deployed CreatorCoin contract instances.
    function getDeployedCreatorCoins()
        public
        view
        returns (CreatorCoin[] memory)
    {
        return deployedCreatorCoins;
    }
}
