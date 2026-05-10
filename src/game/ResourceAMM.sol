// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IResourceAMM.sol";

contract ResourceAMM is Ownable, IResourceAMM {
    using SafeERC20 for IERC20;
    
    IERC20 public tokenA;
    IERC20 public tokenB;
    
    uint256 public reserveA;
    uint256 public reserveB;
    
    uint256 public constant FEE = 30; // 0.3%
    uint256 public constant FEE_DENOMINATOR = 10000;
    
    uint256 public totalLiquidityShares;
    mapping(address => uint256) public liquidityShares;
    
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 shares);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 shares);
    event Swap(address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);
    
    constructor(address _tokenA, address _tokenB) Ownable(msg.sender) {
        require(_tokenA != address(0) && _tokenB != address(0), "Invalid token addresses");
        require(_tokenA != _tokenB, "Tokens must be different");
        
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }
    
    function addLiquidity(uint256 amountA, uint256 amountB) 
        external 
        override 
        returns (uint256 shares) 
    {
        require(amountA > 0 && amountB > 0, "Amounts must be > 0");
        
        tokenA.safeTransferFrom(msg.sender, address(this), amountA);
        tokenB.safeTransferFrom(msg.sender, address(this), amountB);
        
        if (totalLiquidityShares == 0) {
            shares = _sqrt(amountA * amountB);
        } else {
            uint256 sharesA = (amountA * totalLiquidityShares) / reserveA;
            uint256 sharesB = (amountB * totalLiquidityShares) / reserveB;
            shares = sharesA < sharesB ? sharesA : sharesB;
        }
        
        require(shares > 0, "Zero shares minted");
        
        reserveA += amountA;
        reserveB += amountB;
        totalLiquidityShares += shares;
        liquidityShares[msg.sender] += shares;
        
        emit LiquidityAdded(msg.sender, amountA, amountB, shares);
    }
    
    function removeLiquidity(uint256 shares) 
        external 
        override 
        returns (uint256 amountA, uint256 amountB) 
    {
        require(shares > 0 && shares <= liquidityShares[msg.sender], "Invalid shares");
        
        amountA = (shares * reserveA) / totalLiquidityShares;
        amountB = (shares * reserveB) / totalLiquidityShares;
        
        liquidityShares[msg.sender] -= shares;
        totalLiquidityShares -= shares;
        reserveA -= amountA;
        reserveB -= amountB;
        
        tokenA.safeTransfer(msg.sender, amountA);
        tokenB.safeTransfer(msg.sender, amountB);
        
        emit LiquidityRemoved(msg.sender, amountA, amountB, shares);
    }
    
    function swap(address tokenIn, address tokenOut, uint256 amountIn) 
        external 
        override 
        returns (uint256 amountOut) 
    {
        require(amountIn > 0, "Amount must be > 0");
        require(tokenIn == address(tokenA) || tokenIn == address(tokenB), "Invalid tokenIn");
        require(tokenOut == address(tokenA) || tokenOut == address(tokenB), "Invalid tokenOut");
        require(tokenIn != tokenOut, "Cannot swap same token");
        
        uint256 reserveIn = tokenIn == address(tokenA) ? reserveA : reserveB;
        uint256 reserveOut = tokenOut == address(tokenA) ? reserveA : reserveB;
        
        // x * y = k
        uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - FEE);
        amountOut = (amountInWithFee * reserveOut) / (reserveIn * FEE_DENOMINATOR + amountInWithFee);
        require(amountOut > 0, "Insufficient output amount");
        
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).safeTransfer(msg.sender, amountOut);
        
        if (tokenIn == address(tokenA)) {
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            reserveB += amountIn;
            reserveA -= amountOut;
        }
        
        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }
    
    function getReserves() 
        external 
        view 
        override 
        returns (uint256, uint256) 
    {
        return (reserveA, reserveB);
    }
    
    function getAmountOut(uint256 amountIn, address tokenIn, address tokenOut) 
        public 
        view 
        returns (uint256) 
    {
        uint256 reserveIn = tokenIn == address(tokenA) ? reserveA : reserveB;
        uint256 reserveOut = tokenOut == address(tokenA) ? reserveA : reserveB;
        
        uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - FEE);
        return (amountInWithFee * reserveOut) / (reserveIn * FEE_DENOMINATOR + amountInWithFee);
    }
    
    function _sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // pure Solidity version
function sqrtSolidity(uint256 y) public pure returns (uint256 z) {
    if (y > 3) {
        z = y;
        uint256 x = y / 2 + 1;
        while (x < z) {
            z = x;
            x = (y / x + x) / 2;
        }
    } else if (y != 0) {
        z = 1;
    }
}

// Yul assembly version 
function sqrtYul(uint256 y) public pure returns (uint256 z) {
    assembly {
        if gt(y, 3) {
            z := y
            let x := add(div(y, 2), 1)
            for {} lt(x, z) {} {
                z := x
                x := div(add(div(y, x), x), 2)
            }
        }
        if iszero(z) {
            if iszero(iszero(y)) {
                z := 1
            }
        }
    }
}
}