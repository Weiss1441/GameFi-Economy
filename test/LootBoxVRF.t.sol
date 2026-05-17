// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import {VRFV2PlusClient} from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {LootBoxVRF} from "../src/vrf/LootBoxVRF.sol";
import {GameItems} from "../src/game/GameItems.sol";
import {GameParameters} from "../src/game/GameParameters.sol";

interface IVRFConsumerRawFulfill {
    function rawFulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) external;
}

contract MockVRFCoordinatorV2Plus {
    uint256 public nextRequestId = 100;
    VRFV2PlusClient.RandomWordsRequest public lastRequest;

    function requestRandomWords(VRFV2PlusClient.RandomWordsRequest calldata req) external returns (uint256 requestId) {
        lastRequest = req;
        requestId = nextRequestId++;
    }

    function lastSubId() external view returns (uint256) {
        return lastRequest.subId;
    }

    function lastKeyHash() external view returns (bytes32) {
        return lastRequest.keyHash;
    }

    function lastCallbackGasLimit() external view returns (uint32) {
        return lastRequest.callbackGasLimit;
    }

    function lastNumWords() external view returns (uint32) {
        return lastRequest.numWords;
    }

    function fulfill(address consumer, uint256 requestId, uint256 randomness) external {
        uint256[] memory words = new uint256[](1);
        words[0] = randomness;
        IVRFConsumerRawFulfill(consumer).rawFulfillRandomWords(requestId, words);
    }

    function addConsumer(uint256, address) external {}
    function removeConsumer(uint256, address) external {}
    function cancelSubscription(uint256, address) external {}
    function acceptSubscriptionOwnerTransfer(uint256) external {}
    function requestSubscriptionOwnerTransfer(uint256, address) external {}

    function createSubscription() external pure returns (uint256) {
        return 1;
    }

    function getSubscription(uint256) external pure returns (uint96, uint96, uint64, address, address[] memory) {
        address[] memory consumers = new address[](0);
        return (0, 0, 0, address(0), consumers);
    }

    function pendingRequestExists(uint256) external pure returns (bool) {
        return false;
    }

    function getActiveSubscriptionIds(uint256, uint256) external pure returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](0);
        return ids;
    }
    function fundSubscriptionWithNative(uint256) external payable {}
}

contract LootBoxVRFTest is Test {
    MockVRFCoordinatorV2Plus public coordinator;
    GameParameters public params;
    GameItems public items;
    LootBoxVRF public lootBox;

    address public player = address(0xBEEF);
    uint256 public subscriptionId = 123;
    bytes32 public keyHash = bytes32(uint256(456));

    function setUp() public {
        coordinator = new MockVRFCoordinatorV2Plus();
        params = new GameParameters();
        items = new GameItems("Game Items", "GITEMS", address(params));
        lootBox = new LootBoxVRF(address(coordinator), subscriptionId, keyHash, address(items));
        items.grantRole(items.VRF_ROLE(), address(lootBox));
    }

    function test_requestLoot_storesRequestAndPassesVRFConfig() public {
        vm.prank(player);
        uint256 requestId = lootBox.requestLoot();

        (address user, bool fulfilled) = lootBox.requests(requestId);
        assertEq(requestId, 100);
        assertEq(user, player);
        assertFalse(fulfilled);

        assertEq(coordinator.lastSubId(), subscriptionId);
        assertEq(coordinator.lastKeyHash(), keyHash);
        assertEq(coordinator.lastCallbackGasLimit(), lootBox.callbackGasLimit());
        assertEq(coordinator.lastNumWords(), lootBox.numWords());
    }

    function test_fulfillRandomWords_mintsRandomItemAndMarksFulfilled() public {
        vm.prank(player);
        uint256 requestId = lootBox.requestLoot();

        coordinator.fulfill(address(lootBox), requestId, 9);

        (address user, bool fulfilled) = lootBox.requests(requestId);
        assertEq(user, player);
        assertTrue(fulfilled);
        assertEq(items.balanceOf(player, 5), 1);
    }

    function test_revert_rawFulfillFromNonCoordinator() public {
        vm.prank(player);
        uint256 requestId = lootBox.requestLoot();
        uint256[] memory words = new uint256[](1);
        words[0] = 1;

        vm.prank(player);
        vm.expectRevert();
        lootBox.rawFulfillRandomWords(requestId, words);
    }

    function test_revert_fulfillUnknownRequest() public {
        vm.expectRevert("Invalid request");
        coordinator.fulfill(address(lootBox), 999, 1);
    }

    function test_revert_fulfillAlreadyFulfilled() public {
        vm.prank(player);
        uint256 requestId = lootBox.requestLoot();
        coordinator.fulfill(address(lootBox), requestId, 1);

        vm.expectRevert("Already fulfilled");
        coordinator.fulfill(address(lootBox), requestId, 2);
    }

    function test_adminSetters() public {
        lootBox.setCallbackGasLimit(2_000_000);
        lootBox.setKeyHash(bytes32(uint256(999)));
        lootBox.setSubscriptionId(777);
        lootBox.setNativePayment(true);

        assertEq(lootBox.callbackGasLimit(), 2_000_000);
        assertEq(lootBox.keyHash(), bytes32(uint256(999)));
        assertEq(lootBox.subscriptionId(), 777);
        assertTrue(lootBox.nativePayment());
    }

    function test_revert_nonAdminSetter() public {
        vm.prank(player);
        vm.expectRevert();
        lootBox.setNativePayment(true);
    }
}
