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
    TokenC public tokenC;
    UniswapV2Pair public pair1;
    UniswapV2Pair public pair2; 
    address public user = address(0x123);
    address public pairAddress;


    function setUp()public{
        feeManage = new DynamicFeeManage();
        factory = new UniswapV2Factory(address(feeManage));//动态交易费合约的地址
        router = new UniswapV2Router(address(factory));
        tokenA = 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2;
        tokenB = 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48;
        tokenC = 0x2260fac5e5542a773aa44fbcfedf7c193bc2c599;

//创建池子
        pairAddress = factory.createPair(address(tokenA),address(tokenB),0x986b5e1e1755e3c2440e960477f25201b0a8bbd4);
        pair1 = UniswapV2Pair(pairAddress);
        pairAddress = factory.createPair(address(tokenB),address(tokenC),0x230E0321Cf38F09e247e50Afc7801EA2351fe56F);
        pair2 = UniswapV2Pair(pairAddress);

//为用户分配代币
        vm.startPrank(user);
        tokenA.mint(user,10000 ether);
        tokenB.mint(user,10000 ether);
        tokenC.mint(user,10000 ether);
        tokenA.approve(address(router),type(uint256).max);
        tokenB.approve(address(router),type(uint256).max);
        tokenC.approve(address(router),type(uint256).max);
        vm.stopPrank();
    }

    function testAddLiquidityToPair1()public {
//测试首次添加
        vm.startPrank(user);
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1000 ether,
            2000 ether,
            1000 ether,
            2000 ether,
            user
        );
        vm.stopPrank();

        (uint256 reserveA,uint256 reserveB) = pair1.getReserves();
        assertEq(reserveA,1000 ether);
        assertEq(reserveB,2000 ether);
        assertEq(tokenA.balanceOf(user),9000 ether);
        assertEq(tokenB.balanceOf(user),8000 ether);

//测试非首次添加
        vm.startPrank(user);
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1000 ether,
            2000 ether,
            1000 ether,
            2000 ether,
            user
        );
        vm.stopPrank();

        (uint256 reserveA,uint256 reserveB) = pair1.getReserves();
        assertEq(reserveA,1000 ether);
        assertEq(reserveB,2000 ether);
        assertEq(tokenA.balanceOf(user),9000 ether);
        assertEq(tokenB.balanceOf(user),8000 ether);

    }
}
