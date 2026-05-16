// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../game/GameItems.sol";
import "../game/GameParameters.sol";

contract GameFactory {
    event GameDeployed(address indexed gameItems, address indexed gameParams, uint256 salt);

    struct GameDeployment {
        address gameItems;
        address gameParams;
        address deployer;
        uint256 timestamp;
    }

    GameDeployment[] public deployments;

    // CREATE standard deployment
    function deployGameCREATE(string memory name, string memory symbol) external returns (address, address) {
        GameParameters params = new GameParameters();
        GameItems items = new GameItems(name, symbol, address(params));

        deployments.push(
            GameDeployment({
                gameItems: address(items), gameParams: address(params), deployer: msg.sender, timestamp: block.timestamp
            })
        );

        emit GameDeployed(address(items), address(params), 0);
        return (address(items), address(params));
    }

    // CREATE2 deterministic deployment
    function deployGameCREATE2(string memory name, string memory symbol, uint256 salt)
        external
        returns (address, address)
    {
        address params = address(new GameParameters{salt: bytes32(salt)}());
        address items = address(new GameItems{salt: bytes32(salt)}(name, symbol, params));

        deployments.push(
            GameDeployment({gameItems: items, gameParams: params, deployer: msg.sender, timestamp: block.timestamp})
        );

        emit GameDeployed(items, params, salt);
        return (items, params);
    }

    function getDeploymentCount() external view returns (uint256) {
        return deployments.length;
    }

    function predictAddressCREATE2(string memory name, string memory symbol, uint256 salt)
        external
        view
        returns (address params, address items)
    {
        bytes32 saltBytes = bytes32(salt);

        bytes memory paramsCreationCode = type(GameParameters).creationCode;
        bytes32 paramsHash =
            keccak256(abi.encodePacked(bytes1(0xff), address(this), saltBytes, keccak256(paramsCreationCode)));
        params = address(uint160(uint256(paramsHash)));

        bytes memory itemsCreationCode =
            abi.encodePacked(type(GameItems).creationCode, abi.encode(name, symbol, params));
        bytes32 itemsHash =
            keccak256(abi.encodePacked(bytes1(0xff), address(this), saltBytes, keccak256(itemsCreationCode)));
        items = address(uint160(uint256(itemsHash)));
    }
}
