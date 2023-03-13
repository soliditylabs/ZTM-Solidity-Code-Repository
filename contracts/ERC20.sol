// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {console} from "hardhat/console.sol";

contract ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    string public name;
    string public symbol;
    uint8 public immutable decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        return _transfer(msg.sender, to, value);
    }

    function _mint(address to, uint256 value) internal {
        balanceOf[to] += value;
        totalSupply += value;

        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] -= value;
        totalSupply -= value;

        emit Transfer(from, address(0), value);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        require(
            allowance[from][msg.sender] >= value,
            "ERC20: Insufficient allowance"
        );

        allowance[from][msg.sender] -= value;

        emit Approval(from, msg.sender, allowance[from][msg.sender]);

        return _transfer(from, to, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private returns (bool) {
        require(balanceOf[from] >= value, "ERC20: Insufficient sender balance");

        emit Transfer(from, to, value);

        balanceOf[from] -= value;
        balanceOf[to] += value;

        return true;
    }

    function approve(
        address spender,
        uint256 value
    ) external payable returns (bool) {
        allowance[msg.sender][spender] += value;

        emit Approval(msg.sender, spender, value);

        return true;
    }
}
