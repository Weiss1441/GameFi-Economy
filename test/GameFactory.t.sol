// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../src/factory/GameFactory.sol";
import "../src/game/GameItems.sol";
import "../src/game/GameParameters.sol";

contract GameFactoryTest is Test {
    GameFactory public factory;
    address public user1 = address(0x123);
    address public user2 = address(0x456);
    
    string public constant GAME_NAME = "Test Game";
    string public constant GAME_SYMBOL = "TEST";
    
    event GameDeployed(address indexed gameItems, address indexed gameParams, uint256 salt);
    
    function setUp() public {
        factory = new GameFactory();
    }
    
    function test_deployGameCREATE() public {
        vm.prank(user1);
        (address items, address params) = factory.deployGameCREATE(GAME_NAME, GAME_SYMBOL);
        
        assertTrue(items != address(0));
        assertTrue(params != address(0));
        
        GameItems(items).name();
        GameParameters(params);
        
        assertEq(factory.getDeploymentCount(), 1);
    }
    
    function test_deployGameCREATE_emitsEvent() public {
    vm.prank(user1);
    vm.recordLogs();
    
    (address actualItems, address actualParams) = factory.deployGameCREATE(GAME_NAME, GAME_SYMBOL);
    
    Vm.Log[] memory entries = vm.getRecordedLogs();
    bool eventFound = false;
    
    for (uint256 i = 0; i < entries.length; i++) {
        if (entries[i].topics.length == 3 && 
            entries[i].topics[0] == keccak256("GameDeployed(address,address,uint256)")) {
            eventFound = true;
            break;
        }
    }
    
    assertTrue(eventFound);
    }
    
    function test_deployGameCREATE_multipleDeployments() public {
        vm.startPrank(user1);
        
        (address items1, ) = factory.deployGameCREATE("Game1", "G1");
        (address items2, ) = factory.deployGameCREATE("Game2", "G2");
        
        vm.stopPrank();
        
        assertEq(factory.getDeploymentCount(), 2);
        assertTrue(items1 != items2);
    }
    
    function test_deployGameCREATE2() public {
        uint256 salt = 12345;
        
        vm.prank(user1);
        (address items, address params) = factory.deployGameCREATE2(GAME_NAME, GAME_SYMBOL, salt);
        
        assertTrue(items != address(0));
        assertTrue(params != address(0));
        
        assertEq(factory.getDeploymentCount(), 1);
    }
    
    function test_deployGameCREATE2_deterministicAddress() public {
    uint256 salt = 99999;
    
    (address predictedParams, address predictedItems) = factory.predictAddressCREATE2(
        GAME_NAME, GAME_SYMBOL, salt
    );
    
    vm.prank(user1);
    (address actualItems, address actualParams) = factory.deployGameCREATE2(
        GAME_NAME, GAME_SYMBOL, salt
    );
    
    assertEq(actualParams, predictedParams);
    assertEq(actualItems, predictedItems);
    }
    
    function test_deployGameCREATE2_sameSaltSameAddress() public {
        uint256 salt = 77777;
        
        vm.startPrank(user1);
        factory.deployGameCREATE2(GAME_NAME, GAME_SYMBOL, salt);
        vm.stopPrank();
        
        vm.prank(user2);
        vm.expectRevert();
        factory.deployGameCREATE2(GAME_NAME, GAME_SYMBOL, salt);
    }
    
    function test_deployGameCREATE2_differentSaltDifferentAddress() public {
        uint256 salt1 = 11111;
        uint256 salt2 = 22222;
        
        vm.startPrank(user1);
        (address items1, address params1) = factory.deployGameCREATE2(GAME_NAME, GAME_SYMBOL, salt1);
        (address items2, address params2) = factory.deployGameCREATE2(GAME_NAME, GAME_SYMBOL, salt2);
        vm.stopPrank();
        
        assertTrue(items1 != items2);
        assertTrue(params1 != params2);
    }
    
    function test_deployGameCREATE2_emitsEventWithSalt() public {
    uint256 salt = 55555;
    
    vm.prank(user1);
    vm.recordLogs();
    
    factory.deployGameCREATE2(GAME_NAME, GAME_SYMBOL, salt);
    
    Vm.Log[] memory entries = vm.getRecordedLogs();
    bool eventFound = false;
    
    for (uint256 i = 0; i < entries.length; i++) {
        if (entries[i].topics.length == 3 && 
            entries[i].topics[0] == keccak256("GameDeployed(address,address,uint256)")) {
            eventFound = true;
            break;
        }
    }
    
    assertTrue(eventFound);
    }
    
    function test_predictAddressCREATE2_returnsAddress() public view {
        uint256 salt = 44444;
        
        (address params, address items) = factory.predictAddressCREATE2(
            GAME_NAME, GAME_SYMBOL, salt
        );
        
        assertTrue(params != address(0));
        assertTrue(items != address(0));
        assertTrue(params != items);
    }
    
    function test_predictAddressCREATE2_consistent() public view {
        uint256 salt = 88888;
        
        (address params1, address items1) = factory.predictAddressCREATE2(
            GAME_NAME, GAME_SYMBOL, salt
        );
        
        (address params2, address items2) = factory.predictAddressCREATE2(
            GAME_NAME, GAME_SYMBOL, salt
        );
        
        assertEq(params1, params2);
        assertEq(items1, items2);
    }
    
    function test_predictAddressCREATE2_differentNameDifferentAddress() public view {
        uint256 salt = 12345;
        
        (address params1, address items1) = factory.predictAddressCREATE2(
            "Game A", "GA", salt
        );
        
        (address params2, address items2) = factory.predictAddressCREATE2(
            "Game B", "GB", salt
        );
        
        assertTrue(params1 == params2);
        assertTrue(items1 != items2);
    }
    
    function test_getDeploymentCount_initialZero() public view {
        assertEq(factory.getDeploymentCount(), 0);
    }
    
    function test_getDeploymentCount_incrementsAfterDeploy() public {
        assertEq(factory.getDeploymentCount(), 0);
        
        vm.prank(user1);
        factory.deployGameCREATE(GAME_NAME, GAME_SYMBOL);
        
        assertEq(factory.getDeploymentCount(), 1);
        
        vm.prank(user1);
        factory.deployGameCREATE2(GAME_NAME, GAME_SYMBOL, 1);
        
        assertEq(factory.getDeploymentCount(), 2);
    }
    
    function test_mixedCREATEandCREATE2() public {
        vm.startPrank(user1);
        
        (address itemsCreate, ) = factory.deployGameCREATE("CreateGame", "CG");
        (address itemsCreate2, ) = factory.deployGameCREATE2("Create2Game", "C2G", 999);
        
        vm.stopPrank();
        
        assertEq(factory.getDeploymentCount(), 2);
        assertTrue(itemsCreate != itemsCreate2);
        
        GameItems items1 = GameItems(itemsCreate);
        GameItems items2 = GameItems(itemsCreate2);
        
        assertEq(items1.name(), "CreateGame");
        assertEq(items2.name(), "Create2Game");
    }
    
    function test_deploymentByMultipleUsers() public {
        vm.prank(user1);
        (address items1, address params1) = factory.deployGameCREATE("User1Game", "U1G");
        
        vm.prank(user2);
        (address items2, address params2) = factory.deployGameCREATE("User2Game", "U2G");
        
        assertEq(factory.getDeploymentCount(), 2);
        assertTrue(items1 != items2);
        assertTrue(params1 != params2);
    }
    
    function test_revert_deployGameCREATE2_zeroSalt() public {
        vm.prank(user1);
        factory.deployGameCREATE2(GAME_NAME, GAME_SYMBOL, 0);
        
        vm.prank(user1);
        vm.expectRevert();
        factory.deployGameCREATE2(GAME_NAME, GAME_SYMBOL, 0);
    }
    
    function testFuzz_deployGameCREATE2_differentSalts(uint256 salt) public {
        vm.assume(salt > 0);
        
        vm.prank(user1);
        (address items, address params) = factory.deployGameCREATE2(GAME_NAME, GAME_SYMBOL, salt);
        
        assertTrue(items != address(0));
        assertTrue(params != address(0));
    }
    
    function testFuzz_predictAddressCREATE2_neverZero(uint256 salt) public view {
        (address params, address items) = factory.predictAddressCREATE2(
            GAME_NAME, GAME_SYMBOL, salt
        );
        
        assertTrue(params != address(0));
        assertTrue(items != address(0));
    }
}