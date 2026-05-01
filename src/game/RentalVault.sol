// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IRentalVault.sol";

contract RentalVault is Ownable, ReentrancyGuard, ERC1155Holder, IRentalVault {
    IERC1155 public gameItems;
    
    struct Rental {
        address owner;
        address renter;
        uint256 expiry;
    }
    
    mapping(uint256 => Rental) public rentals;
    mapping(uint256 => uint256) public depositedAmounts;
    
    uint256 public defaultRentalDuration = 7 days;
    uint256 public rentalFee = 0.01 ether;
    
    event NFTRented(uint256 indexed tokenId, address indexed owner, address indexed renter, uint256 expiry);
    event NFTReclaimed(uint256 indexed tokenId, address indexed owner);
    event NFTReturned(uint256 indexed tokenId, address indexed renter);
    
    constructor(address _gameItems) Ownable(msg.sender) {
        gameItems = IERC1155(_gameItems);
    }
    
    function deposit(uint256 tokenId, uint256 amount) 
        external 
        override 
        nonReentrant 
    {
        require(amount > 0, "Amount must be > 0");
        require(rentals[tokenId].renter == address(0), "Item is currently rented");
        
        gameItems.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        depositedAmounts[tokenId] += amount;
        
        if (rentals[tokenId].owner == address(0)) {
            rentals[tokenId].owner = msg.sender;
        }
    }
    
    function rent(uint256 tokenId, address renter, uint256 duration) 
        external 
        override 
        nonReentrant 
    {
        require(rentals[tokenId].owner != address(0), "Item not deposited");
        require(rentals[tokenId].renter == address(0), "Item already rented");
        require(block.timestamp > rentals[tokenId].expiry, "Previous rental not expired");
        
        uint256 rentDuration = duration == 0 ? defaultRentalDuration : duration;
        
        rentals[tokenId].renter = renter;
        rentals[tokenId].expiry = block.timestamp + rentDuration;
        
        emit NFTRented(tokenId, rentals[tokenId].owner, renter, rentals[tokenId].expiry);
    }
    
    function reclaim(uint256 tokenId) 
        external 
        override 
        nonReentrant 
    {
        require(rentals[tokenId].owner == msg.sender, "Not the owner");
        require(rentals[tokenId].renter == address(0) || block.timestamp > rentals[tokenId].expiry, "Item is rented");
        
        uint256 amount = depositedAmounts[tokenId];
        require(amount > 0, "No deposited amount");
        
        depositedAmounts[tokenId] = 0;
        rentals[tokenId].renter = address(0);
        rentals[tokenId].expiry = 0;
        
        gameItems.safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
        
        emit NFTReclaimed(tokenId, msg.sender);
    }
    
    function returnNft(uint256 tokenId) 
        external 
        nonReentrant 
    {
        require(rentals[tokenId].renter == msg.sender, "Not the renter");
        
        rentals[tokenId].renter = address(0);
        
        emit NFTReturned(tokenId, msg.sender);
    }
    
    function isRented(uint256 tokenId) 
        external 
        view 
        override 
        returns (bool) 
    {
        return rentals[tokenId].renter != address(0) && block.timestamp <= rentals[tokenId].expiry;
    }
    
    function setDefaultRentalDuration(uint256 _duration) external onlyOwner {
        defaultRentalDuration = _duration;
    }
    
    function setRentalFee(uint256 _fee) external onlyOwner {
        rentalFee = _fee;
    }
}