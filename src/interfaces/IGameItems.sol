// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IGameItems is IERC1155 {
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;
    function burn(address from, uint256 id, uint256 amount) external;
    function craft(uint256[] memory ingredients, uint256 resultId) external returns (uint256);
}