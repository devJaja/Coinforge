// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {ERC20} from "forge-std/interfaces/IERC20.sol"; // Using a mock ERC20 interface from forge-std for compilation

contract CreatorCoin is ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Bonding curve parameters (placeholder)
    address public reserveToken; // e.g., WETH, USDC
    uint256 public constant INITIAL_TOKEN_PRICE = 1 ether; // 1 unit of reserveToken for 1 CreatorCoin
    uint256 public constant PRICE_INCREASE_FACTOR = 1000000000000000; // Adjust as needed
    uint256 public constant ROYALTIES_PERCENTAGE = 5; // 5% royalties (0-100)
    address public immutable treasuryAddress;

    // Events
    event TokensPurchased(address indexed buyer, uint256 amountInReserveToken, uint256 amountOfCreatorCoin);
    event TokensSold(address indexed seller, uint256 amountInCreatorCoin, uint256 amountOutReserveToken);
    event RoyaltiesPaid(address indexed beneficiary, uint256 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        address _reserveToken,
        address _treasuryAddress
    ) {
        name = _name;
        symbol = _symbol;
        reserveToken = _reserveToken;
        treasuryAddress = _treasuryAddress;
        _totalSupply = 0; // Coins are minted on demand
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // --- Bonding Curve Logic (Simplified Placeholder) ---
    // In a real scenario, this would interact with a more complex curve or an Automated Market Maker (AMM)
    // The price increases with demand (more tokens minted) and decreases with supply (tokens burned).

    function getCurrentPrice() public view returns (uint256) {
        // Simplified price calculation: price increases with total supply
        // This is a very basic example; real bonding curves are more complex.
        return INITIAL_TOKEN_PRICE + (_totalSupply / PRICE_INCREASE_FACTOR);
    }

    function buy(uint256 amountInReserveToken) public returns (uint256) {
        require(amountInReserveToken > 0, "Buy amount must be positive");

        // Transfer reserve token from buyer to this contract
        // In a real scenario, this would be an actual token transfer using IERC20.transferFrom
        // For this placeholder, we simulate the transfer.
        // IERC20(reserveToken).transferFrom(msg.sender, address(this), amountInReserveToken);

        uint256 currentPrice = getCurrentPrice();
        uint256 amountOfCreatorCoin = amountInReserveToken / currentPrice;
        require(amountOfCreatorCoin > 0, "Not enough reserve token to buy any CreatorCoin");

        _mint(msg.sender, amountOfCreatorCoin);

        emit TokensPurchased(msg.sender, amountInReserveToken, amountOfCreatorCoin);
        return amountOfCreatorCoin;
    }

    function sell(uint256 amountOfCreatorCoin) public returns (uint256) {
        require(amountOfCreatorCoin > 0, "Sell amount must be positive");
        require(_balances[msg.sender] >= amountOfCreatorCoin, "Insufficient CreatorCoin balance to sell");

        uint256 currentPrice = getCurrentPrice();
        uint256 amountOutReserveToken = amountOfCreatorCoin * currentPrice;

        // Calculate and distribute royalties
        uint256 royalties = (amountOutReserveToken * ROYALTIES_PERCENTAGE) / 100;
        uint256 netAmount = amountOutReserveToken - royalties;

        // Transfer royalties to the treasury
        // IERC20(reserveToken).transfer(treasuryAddress, royalties);
        emit RoyaltiesPaid(treasuryAddress, royalties);

        // Transfer reserve token from this contract back to seller
        // IERC20(reserveToken).transfer(msg.sender, netAmount);

        _burn(msg.sender, amountOfCreatorCoin);

        emit TokensSold(msg.sender, amountOfCreatorCoin, netAmount);
        return netAmount;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        require(_balances[account] >= amount, "ERC20: burn amount exceeds balance");

        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
}
