// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20AtomicSwap {

    /**
     * @dev Swap Information
     */
    struct Swap {
        address sender;
        address receiver;
        bytes32 secretHash;
        uint256 amount;
    }

    /**
     * @dev INVALID(swap has not been initialized), PENDING(swap is in progress), COMPLETE(swap has been redeemed), CANCELED(refunded)
     */
    enum Stage {
        INVALID,
        PENDING,
        COMPLETED,
        CANCELED
    }

    mapping(bytes32 => Swap) public _swaps;
    mapping(bytes32 => Stage) public _swapStatus;

    /**
     * @dev Contract Name / Symbol / Address
     */
    string contractName;
    string contractSymbol;
    uint8 contractDecimals;
    
    address contractAddress;

    event SwapCreated(bytes32 indexed secretHash, address tokenAddress, address sender, address receiver, uint256 amount);
    event Redeemed(bytes32 indexed secretHash, bytes secret);
    event Refunded(bytes32 secretHash);


    error InsufficientAllowance(address tokenAddress, address owner, address spender, uint256 amount,uint256 allowance);

    constructor(address tokenAddress_) {
       contractAddress = tokenAddress_; 
       contractName = IERC20Metadata(tokenAddress_).name();
       contractSymbol = IERC20Metadata(tokenAddress_).symbol();
       contractDecimals = IERC20Metadata(tokenAddress_).decimals();
    }

    function name() public view returns(string memory) {
        return contractName;
    }

    function symbol() public view returns(string memory) {
        return contractSymbol;
    }

    function decimals() public view returns(uint8) {
        return contractDecimals;
    }

    function addressOfContract() public view returns(address) {
        return contractAddress;
    }
    /**
     * @dev create ERC20 swap info.
     */
    function createSwap(address initiator_, address receiver_, bytes32 secretHash_, uint256 amount_) public {

        require(amount_ != 0, "the amount cannot be zero");

        uint256 balance = IERC20(contractAddress).balanceOf(initiator_);
        require(balance >= amount_, "insufficient balance");

        uint256 allowedAmount = IERC20(contractAddress).allowance(initiator_, address(this));
        if(allowedAmount == 0 || allowedAmount < amount_) {
            revert InsufficientAllowance(contractAddress, initiator_, address(this), amount_, allowedAmount);
        }

        require(_swapStatus[secretHash_] == Stage.INVALID, "hash is already exists");
        
        Swap memory initSwap = Swap({
            sender: initiator_,
            receiver: receiver_,
            secretHash: secretHash_,
            amount: amount_
        });

        bool isTransferSuccess = IERC20(contractAddress).transferFrom(initiator_, address(this), amount_);
        require(isTransferSuccess, "fail to transfer");

        _swaps[secretHash_]=initSwap;
        _swapStatus[secretHash_]=Stage.PENDING;

        emit SwapCreated(secretHash_, contractAddress, initiator_, receiver_, amount_);
    }

    /**
     * @dev redeem ERC20 token 
     */
    function redeem(bytes memory secret_, bytes32 secretHash_) public {

        require(_swapStatus[secretHash_] != Stage.COMPLETED, "swap is already completed");

        Swap memory pendingSwap = _swaps[secretHash_];

        require(keccak256(abi.encodePacked(secret_)) == pendingSwap.secretHash, "secret is not matched with swap");

        bool isTransferSuccess = IERC20(contractAddress).transfer(pendingSwap.receiver, pendingSwap.amount);

        require(isTransferSuccess, "fail to transfer");

        _swapStatus[secretHash_] = Stage.COMPLETED;

    }

    /**
     * @dev refund ERC20 token
     */
    function refund(bytes32 secretHash_) public {
        require(_swapStatus[secretHash_] != Stage.CANCELED, "swap is already canceled");
        require(_swapStatus[secretHash_] != Stage.COMPLETED, "swap is already completed");

        Swap memory pendingSwap = _swaps[secretHash_];


        bool isTransferSuccess = IERC20(contractAddress).transfer(pendingSwap.sender, pendingSwap.amount);

        require(isTransferSuccess, "fail to transfer");

        _swapStatus[secretHash_] = Stage.CANCELED;
    }

    /**
     * @dev get swap info.
     */
    function getSwap(bytes32 secretHash_) public view returns(Swap memory) {
        return _swaps[secretHash_];
    }

    /**
     * @dev get status of swap
     */
    function getSwapStatus(bytes32 secretHash_) public view returns(Stage) {
        return _swapStatus[secretHash_];
    }

    /**
     * @dev check whether the swap is already redeemed or not
     */
    function isRedeemed(bytes32 secretHash) public view returns(bool) {
        require(_swapStatus[secretHash] != Stage.INVALID, "swap hash is not valid");
        return _swapStatus[secretHash] == Stage.COMPLETED ? true : false;
    }
    
    /**
     * @dev check whether the swap is already refunded or not
     */
    function isRefunded(bytes32 secretHash) public view returns(bool) {
        require(_swapStatus[secretHash] != Stage.INVALID, "swap hash is not valid");
        return _swapStatus[secretHash] == Stage.CANCELED ? true : false;
    }

}