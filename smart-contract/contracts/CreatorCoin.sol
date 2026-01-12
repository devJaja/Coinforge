// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Errors} from "./libs/Errors.sol";
import {Events} from "./libs/Events.sol";


contract CreatorCoin is ERC20, Ownable, Pausable {
    using SafeERC20 for IERC20;
    // Bonding curve parameters (placeholder)
    IERC20 public immutable reserveToken; // e.g., WETH, USDC
    uint256 public constant INITIAL_TOKEN_PRICE = 1 ether; // 1 unit of reserveToken for 1 CreatorCoin
    uint256 public constant PRICE_INCREASE_FACTOR = 1000000000000000; // Adjust as needed
    uint256 public royaltiesPercentage; // 5% royalties (0-100)
    address public immutable treasuryAddress;

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

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20)
        whenNotPaused
    {
        super._update(from, to, value);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setRoyaltyRate(uint256 newRate) public onlyOwner {
        if (newRate > 100) {
            revert Errors.CreatorCoin__InvalidRoyaltyPercentage(newRate);
        }
        emit Events.RoyaltyRateUpdated(royaltiesPercentage, newRate);
        royaltiesPercentage = newRate;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }

    function getCurrentPrice() public view returns (uint256) {
        return INITIAL_TOKEN_PRICE + (totalSupply() / PRICE_INCREASE_FACTOR);
    }

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
