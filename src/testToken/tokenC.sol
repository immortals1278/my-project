// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract TokenC is ERC20, Ownable {
    constructor() ERC20("TokenC", "TKC") Ownable(msg.sender) {
        
    
    }
}