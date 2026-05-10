// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GameVault is ERC4626, Ownable {
    uint256 public yieldRate = 500; // 5% APY 
    uint256 public lastYieldUpdate;
    
    constructor(IERC20 asset)
        ERC4626(asset)
        ERC20("GameFi Vault Shares", "vGFI")
        Ownable(msg.sender)
    {
        lastYieldUpdate = block.timestamp;
    }
    
    function setYieldRate(uint256 _rate) external onlyOwner {
        require(_rate <= 10000, "Rate too high");
        yieldRate = _rate;
    }
    
    
    function totalAssets() public view override returns (uint256) {
        return super.totalAssets();
    }
    
    
    function getProjectedAssets(uint256 assets, uint256 timeElapsed) public view returns (uint256) {
        uint256 yearlyYield = (assets * yieldRate) / 10000;
        uint256 proportionalYield = (yearlyYield * timeElapsed) / 365 days;
        return assets + proportionalYield;
    }
}