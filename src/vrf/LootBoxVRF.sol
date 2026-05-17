// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {VRFConsumerBaseV2Plus} from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

interface ILootGameItems {
    function mintFromVRF(address to, uint256 itemId) external;
}

contract LootBoxVRF is VRFConsumerBaseV2Plus, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    ILootGameItems public immutable gameItems;

    uint256 public subscriptionId;
    bytes32 public keyHash;
    uint32 public callbackGasLimit = 250000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;
    bool public nativePayment;

    struct LootRequest {
        address user;
        bool fulfilled;
    }

    mapping(uint256 => LootRequest) public requests;

    event LootRequested(address indexed user, uint256 indexed requestId);
    event LootMinted(address indexed user, uint256 itemId, uint256 rarity);

    constructor(address vrfCoordinator, uint256 _subscriptionId, bytes32 _keyHash, address gameItemsAddress)
        VRFConsumerBaseV2Plus(vrfCoordinator)
    {
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        gameItems = ILootGameItems(gameItemsAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    function requestLoot() external returns (uint256 requestId) {
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: nativePayment}))
            })
        );

        requests[requestId] = LootRequest({user: msg.sender, fulfilled: false});

        emit LootRequested(msg.sender, requestId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        LootRequest storage req = requests[requestId];

        require(req.user != address(0), "Invalid request");
        require(!req.fulfilled, "Already fulfilled");

        req.fulfilled = true;

        uint256 randomness = randomWords[0];
        uint256 itemId = (randomness % 5) + 1;
        uint256 rarity = randomness % 100;

        gameItems.mintFromVRF(req.user, itemId);

        emit LootMinted(req.user, itemId, rarity);
    }

    function setCallbackGasLimit(uint32 gasLimit) external onlyRole(ADMIN_ROLE) {
        callbackGasLimit = gasLimit;
    }

    function setKeyHash(bytes32 _keyHash) external onlyRole(ADMIN_ROLE) {
        keyHash = _keyHash;
    }

    function setSubscriptionId(uint256 _subId) external onlyRole(ADMIN_ROLE) {
        subscriptionId = _subId;
    }

    function setNativePayment(bool enabled) external onlyRole(ADMIN_ROLE) {
        nativePayment = enabled;
    }
}
