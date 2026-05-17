// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "../interfaces/IGameItems.sol";
import "../interfaces/IGameParameters.sol";

contract GameItems is ERC1155, AccessControl, IGameItems {
    string public name;
    string public symbol;

    IGameParameters public gameParams;

    bytes32 public constant VRF_ROLE = keccak256("VRF_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(uint256 => uint256[]) public craftingRecipes;
    mapping(uint256 => uint256) public recipeResults;

    constructor(
        string memory _name,
        string memory _symbol,
        address _gameParams
    )
        ERC1155("https://api.gamefi.com/items/{id}.json")
    {
        name = _name;
        symbol = _symbol;
        gameParams = IGameParameters(_gameParams);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(VRF_ROLE, msg.sender);
    }

    function mintFromVRF(address to, uint256 id) external onlyRole(VRF_ROLE) {
        _mint(to, id, 1, "");
    }

    function mint(address to, uint256 id, uint256 amount, bytes memory data)
        public
        override
        onlyRole(ADMIN_ROLE)
    {
        _mint(to, id, amount, data);
    }

    function burn(address from, uint256 id, uint256 amount) public override {
        require(from == msg.sender || isApprovedForAll(from, msg.sender));
        _burn(from, id, amount);
    }

    function craft(uint256[] memory ingredients, uint256 resultId)
        public
        override
        returns (uint256)
    {
        require(ingredients.length > 0);

        for (uint256 i = 0; i < ingredients.length; i++) {
            _burn(msg.sender, ingredients[i], 1);
        }

        _mint(msg.sender, resultId, 1, "");
        return 1;
    }

    function setCraftingRecipe(uint256[] memory ingredients, uint256 result)
        public
        onlyRole(ADMIN_ROLE)
    {
        craftingRecipes[result] = ingredients;
        recipeResults[uint256(keccak256(abi.encodePacked(ingredients)))] = result;
    }

    function uri(uint256 tokenId) public pure override returns (string memory) {
        return string(
            abi.encodePacked(
                "https://api.gamefi.com/items/",
                Strings.toString(tokenId),
                ".json"
            )
        );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}