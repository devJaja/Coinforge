// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Errors} from "./libs/Errors.sol";
import {Events} from "./libs/Events.sol";

/// @title CreatorCoin
/// @author CoinForge Team
/// @notice A contract for creating a personal or community token with a bonding curve.
/// @dev This contract implements an ERC20 token with features like pausing, ownership,
/// and a bonding curve for buying and selling tokens. It includes a royalty mechanism
/// on token sales, which is directed to a treasury address.
contract CreatorCoin is ERC20, Ownable, Pausable {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                           STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The ERC20 token used as a reserve for the bonding curve (e.g., WETH, USDC).
    IERC20 public immutable reserveToken;

    /// @dev The initial price of the CreatorCoin in terms of the reserve token.
    uint256 public constant INITIAL_TOKEN_PRICE = 1 ether; // 1 unit of reserveToken for 1 CreatorCoin

    /// @dev The factor by which the price of the CreatorCoin increases with each unit of total supply.
    uint256 public constant PRICE_INCREASE_FACTOR = 1000000000000000; // Adjust as needed

    /// @notice The percentage of token sale proceeds that are sent to the treasury as royalties.
    uint256 public royaltiesPercentage; // 5% royalties (0-100)

    /// @notice The address that receives the royalties from token sales.
    address public immutable treasuryAddress;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Constructs the CreatorCoin contract.
    /// @param _name The name of the new CreatorCoin.
    /// @param _symbol The symbol of the new CreatorCoin.
    /// @param _reserveToken The address of the ERC-20 token used as a reserve.
    /// @param _treasuryAddress The address designated to receive royalties.
    /// @param _initialRoyaltyPercentage The initial percentage of royalties for the creator.
    constructor(
        string memory _name,
        string memory _symbol,
        address _reserveToken,
        address _treasuryAddress,
        uint256 _initialRoyaltyPercentage
    )
        ERC20(_name, _symbol)
        Ownable(msg.sender) // Set the deployer as the initial owner
    {
        if (_reserveToken == address(0)) {
            revert Errors.CreatorCoin__ZeroReserveTokenAddress();
        }
        if (_treasuryAddress == address(0)) {
            revert Errors.CreatorCoin__ZeroTreasuryAddress();
        }
        if (_initialRoyaltyPercentage > 100) {
            revert Errors.CreatorCoin__InvalidRoyaltyPercentage(_initialRoyaltyPercentage);
        }

        reserveToken = IERC20(_reserveToken);
        treasuryAddress = _treasuryAddress;
        royaltiesPercentage = _initialRoyaltyPercentage;
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Overrides the internal _update function of ERC20 to add pause functionality.
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20)
        whenNotPaused
    {
        super._update(from, to, value);
    }

    /*//////////////////////////////////////////////////////////////
                         OWNER ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Pauses the contract, preventing token transfers, buys, and sells.
    /// @dev Can only be called by the owner.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract, re-enabling token transfers, buys, and sells.
    /// @dev Can only be called by the owner.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Sets the royalty rate for token sales.
    /// @dev Can only be called by the owner. The new rate cannot exceed 100.
    /// @param newRate The new royalty percentage (0-100).
    function setRoyaltyRate(uint256 newRate) public onlyOwner {
        if (newRate > 100) {
            revert Errors.CreatorCoin__InvalidRoyaltyPercentage(newRate);
        }
        emit Events.RoyaltyRateUpdated(royaltiesPercentage, newRate);
        royaltiesPercentage = newRate;
    }

    /// @notice Mints new tokens and assigns them to a specified address.
    /// @dev Can only be called by the owner.
    /// @param to The address to receive the new tokens.
    /// @param amount The amount of tokens to mint.
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /// @notice Burns a specified amount of tokens from a specified address.
    /// @dev Can only be called by the owner.
    /// @param from The address to burn tokens from.
    /// @param amount The amount of tokens to burn.
    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculates the current price of one CreatorCoin based on the total supply.
    /// @dev The price increases linearly with the total supply.
    /// @return The current price of one CreatorCoin in terms of the reserve token.
    function getCurrentPrice() public view returns (uint256) {
        return INITIAL_TOKEN_PRICE + (totalSupply() / PRICE_INCREASE_FACTOR);
    }

    /// @notice Buys CreatorCoins by spending the reserve token.
    /// @dev The amount of CreatorCoins received depends on the current price.
    /// @param amountInReserveToken The amount of reserve tokens to spend.
    /// @return The amount of CreatorCoins purchased.
    function buy(uint256 amountInReserveToken) public whenNotPaused returns (uint256) {
        if (amountInReserveToken == 0) {
            revert Errors.CreatorCoin__ZeroBuyAmount();
        }

        reserveToken.safeTransferFrom(msg.sender, address(this), amountInReserveToken);

        uint256 currentPrice = getCurrentPrice();
        uint256 amountOfCreatorCoin = amountInReserveToken / currentPrice;
        if (amountOfCreatorCoin == 0) {
            revert Errors.CreatorCoin__InsufficientReserveTokenAmount();
        }

        _mint(msg.sender, amountOfCreatorCoin);

        emit Events.TokensPurchased(msg.sender, amountInReserveToken, amountOfCreatorCoin);
        return amountOfCreatorCoin;
    }

    /// @notice Sells CreatorCoins to receive the reserve token.
    /// @dev A percentage of the sale amount is sent to the treasury as royalties.
    /// @param amountOfCreatorCoin The amount of CreatorCoins to sell.
    /// @return The net amount of reserve tokens received after royalties.
    function sell(uint256 amountOfCreatorCoin) public whenNotPaused returns (uint256) {
        if (amountOfCreatorCoin == 0) {
            revert Errors.CreatorCoin__ZeroSellAmount();
        }
        if (balanceOf(msg.sender) < amountOfCreatorCoin) {
            revert Errors.CreatorCoin__InsufficientBalanceToSell(amountOfCreatorCoin, balanceOf(msg.sender));
        }

        uint256 currentPrice = getCurrentPrice();
        uint256 amountOutReserveToken = amountOfCreatorCoin * currentPrice;

        uint256 royalties = (amountOutReserveToken * royaltiesPercentage) / 100;
        uint256 netAmount = amountOutReserveToken - royalties;

        reserveToken.safeTransfer(treasuryAddress, royalties);
        emit Events.RoyaltiesPaid(treasuryAddress, royalties);

        reserveToken.safeTransfer(msg.sender, netAmount);

        _burn(msg.sender, amountOfCreatorCoin);

        emit Events.TokensSold(msg.sender, amountOfCreatorCoin, netAmount);
        return netAmount;
    }
}
