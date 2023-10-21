// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
// 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
contract HoneyToken is ERC20 {
    constructor() ERC20("HoneyToken","HYT") {
        _mint(msg.sender,10_000 * 1_000_000_000_000_000_000);
    }
}