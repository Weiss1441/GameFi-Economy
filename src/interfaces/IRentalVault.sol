// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IRentalVault {
    function deposit(uint256 tokenId, uint256 amount) external;
    function rent(uint256 tokenId, address renter, uint256 duration) external;
    function reclaim(uint256 tokenId) external;
    function returnNft(uint256 tokenId) external;
    function isRented(uint256 tokenId) external view returns (bool);
}
