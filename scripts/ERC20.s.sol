// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// --verify not yet working in Hardhat project

import {Script} from "forge-std/Script.sol";
import {ERC20} from "../contracts/ERC20.sol";

contract ERC20Script is Script {
    function setUp() public {}

    function run() public {
        uint256 key = vm.envUint("PRIVATE_KEY");
        vm.broadcast(key);

        new ERC20("Name", "SYM", 18);
    }
}
