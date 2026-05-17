// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract GameVaultV1 is
    Initializable,
    ERC4626Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

    
    uint256 private _status;
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED     = 2;

    modifier nonReentrant() {
        require(_status != ENTERED, "ReentrancyGuard: reentrant call");
        _status = ENTERED;
        _;
        _status = NOT_ENTERED;
    }

    
    uint256 public yieldRate;
    uint256 public lastYieldUpdate;
    uint256 public totalFeesCollected;
    uint256 public feeBps;
    address public feeRecipient;

    uint256 public constant MAX_YIELD_RATE = 10000;
    uint256 public constant MAX_FEE_BPS    = 1000;

    
    event YieldRateUpdated(uint256 oldYieldRate, uint256 newYieldRate);
    event FeeCollected(address indexed payer, uint256 amount);
    event FeeUpdated(uint256 oldBps, uint256 newBps);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);

    
    error YieldRateTooHigh(uint256 requested, uint256 max);
    error FeeTooHigh(uint256 requested, uint256 max);
    error ZeroAddress();
    error ZeroAmount();

    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    
    function initialize(
        address asset_,
        string memory name_,
        string memory symbol_,
        uint256 initialYieldRate_,
        address feeRecipient_,
        uint256 feeBps_
    ) external initializer {
        __ERC4626_init(IERC20(asset_));
        __ERC20_init(name_, symbol_);
        __Ownable_init(msg.sender);
      

        if (initialYieldRate_ > MAX_YIELD_RATE) revert YieldRateTooHigh(initialYieldRate_, MAX_YIELD_RATE);
        if (feeBps_ > MAX_FEE_BPS) revert FeeTooHigh(feeBps_, MAX_FEE_BPS);
        if (feeRecipient_ == address(0)) revert ZeroAddress();

        yieldRate       = initialYieldRate_;
        feeBps          = feeBps_;
        feeRecipient    = feeRecipient_;
        lastYieldUpdate = block.timestamp;
        _status         = NOT_ENTERED;
    }

    

    function deposit(uint256 assets, address receiver)
        public
        override
        virtual
        nonReentrant
        returns (uint256 shares)
    {
        if (assets == 0) revert ZeroAmount();
        require(assets <= maxDeposit(receiver), "ERC4626: deposit more than max");

        uint256 fee           = (assets * feeBps) / 10000;
        uint256 assetsAfterFee = assets - fee;

        shares = previewDeposit(assetsAfterFee);

        //CEI
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), assets);

        if (fee > 0) {
            IERC20(asset()).safeTransfer(feeRecipient, fee);
            totalFeesCollected += fee;
            emit FeeCollected(msg.sender, fee);
        }

        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assetsAfterFee, shares);
    }

    function withdraw(uint256 assets, address receiver, address owner_)
        public
        override
        virtual
        nonReentrant
        returns (uint256 shares)
    {
        if (assets == 0) revert ZeroAmount();
        require(assets <= maxWithdraw(owner_), "ERC4626: withdraw more than max");

        shares = previewWithdraw(assets);

        if (msg.sender != owner_) {
            _spendAllowance(owner_, msg.sender, shares);
        }

        // CEI
        _burn(owner_, shares);
        IERC20(asset()).safeTransfer(receiver, assets);
        emit Withdraw(msg.sender, receiver, owner_, assets, shares);
    }

   

    function getProjectedAssets(uint256 assets, uint256 timeElapsed)
        public
        view
        returns (uint256)
    {
        uint256 yearlyYield      = (assets * yieldRate) / 10000;
        uint256 proportionalYield = (yearlyYield * timeElapsed) / 365 days;
        return assets + proportionalYield;
    }

    

    function setYieldRate(uint256 newRate) external onlyOwner {
        if (newRate > MAX_YIELD_RATE) revert YieldRateTooHigh(newRate, MAX_YIELD_RATE);
        emit YieldRateUpdated(yieldRate, newRate);
        yieldRate       = newRate;
        lastYieldUpdate = block.timestamp;
    }

    function setFeeBps(uint256 newFeeBps) external onlyOwner {
        if (newFeeBps > MAX_FEE_BPS) revert FeeTooHigh(newFeeBps, MAX_FEE_BPS);
        emit FeeUpdated(feeBps, newFeeBps);
        feeBps = newFeeBps;
    }

    function setFeeRecipient(address newRecipient) external onlyOwner {
        if (newRecipient == address(0)) revert ZeroAddress();
        emit FeeRecipientUpdated(feeRecipient, newRecipient);
        feeRecipient = newRecipient;
    }

    

    function _authorizeUpgrade(address) internal override onlyOwner {}

    
    uint256[44] private __gap;
}