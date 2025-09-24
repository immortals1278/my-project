// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/UniswapV2Router.sol";
import "../src/UniswapV2Factory.sol";
import "../src/DynamicFeeManage.sol";
import "../src/UniswapV2Pair.sol";
import "../src/testToken/tokenA.sol";
import "../src/testToken/tokenB.sol";

contract UniswapV2DynamicTest is Test {
    UniswapV2Router public router;
    UniswapV2Factory public factory;
    DynamicFeeManage public feeManage;
    TokenA public tokenA;
    TokenB public tokenB;
    UniswapV2Pair public pair;
    address public user = address(0x123);
    address public pairAddress;


    function setUp()public{
        feeManage = new DynamicFeeManage();
        factory = new UniswapV2Factory(address(feeManage));//动态交易费合约的地址
        router = new UniswapV2Router(address(factory));
        tokenA = new TokenA();
        tokenB = new TokenB();

        pairAddress = factory.createPair(address(tokenA),address(tokenB));
        pair = UniswapV2Pair(pairAddress);

        vm.startPrank(user);
        tokenA.mint(user,10000 ether);
        tokenB.mint(user,10000 ether);
        tokenA.approve(address(router),type(uint256).max);
        tokenB.approve(address(router),type(uint256).max);
        vm.stopPrank();
    }
}
