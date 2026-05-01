// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/IGameItems.sol";
import "../interfaces/IGameParameters.sol";

contract GameItems is ERC1155, Ownable, IGameItems {
    string public name;
    string public symbol;
    
    mapping(uint256 => uint256[]) public craftingRecipes;
    mapping(uint256 => uint256) public recipeResults;
    
    IGameParameters public gameParams;
    
    constructor(string memory _name, string memory _symbol, address _gameParams) 
        ERC1155("https://api.gamefi.com/items/{id}.json") 
        Ownable(msg.sender)
    {
        name = _name;
        symbol = _symbol;
        gameParams = IGameParameters(_gameParams);
    }
    
    function mint(address to, uint256 id, uint256 amount, bytes memory data) 
        public 
        override 
        onlyOwner 
    {
        _mint(to, id, amount, data);
    }
    
    function burn(address from, uint256 id, uint256 amount) 
        public 
        override 
    {
        require(from == msg.sender || isApprovedForAll(from, msg.sender), "Not authorized");
        _burn(from, id, amount);
    }
    
    function craft(uint256[] memory ingredients, uint256 resultId) 
        public 
        override 
        returns (uint256) 
    {
        require(ingredients.length > 0, "No ingredients");
        
        for (uint i = 0; i < ingredients.length; i++) {
            _burn(msg.sender, ingredients[i], 1);
        }
        
        uint256 amount = 1;
        _mint(msg.sender, resultId, amount, "");
        
        return amount;
    }
    
    function setCraftingRecipe(uint256[] memory ingredients, uint256 result) 
        public 
        onlyOwner 
    {
        craftingRecipes[result] = ingredients;
        recipeResults[uint256(keccak256(abi.encodePacked(ingredients)))] = result;
    }
    
    function uri(uint256 tokenId) 
        public 
        pure 
        override 
        returns (string memory) 
    {
        return string(abi.encodePacked("https://api.gamefi.com/items/", Strings.toString(tokenId), ".json"));
    }
}