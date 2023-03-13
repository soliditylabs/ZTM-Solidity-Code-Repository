// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC20} from "./ERC20.sol";

contract DepositorCoin is ERC20 {
    address public owner;
    uint256 public unlockTime;

    modifier isUnlocked() {
        require(block.timestamp >= unlockTime, "DPC: Still locked");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _lockTime,
        address _initialOwner,
        uint256 _initialSupply
    ) ERC20(_name, _symbol, 18) {
        owner = msg.sender;
        unlockTime = block.timestamp + _lockTime;

        _mint(_initialOwner, _initialSupply);
    }

    function mint(address to, uint256 value) external isUnlocked {
        require(msg.sender == owner, "DPC: Only owner can mint");

        _mint(to, value);
    }

    function burn(address from, uint256 value) external isUnlocked {
        require(msg.sender == owner, "DPC: Only owner can burn");

        _burn(from, value);
    }
}
