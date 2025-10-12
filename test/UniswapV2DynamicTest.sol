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
    uint256 amountA;
    uint256 amountB;
    uint256 liquidity;
    
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

        vm.startPrank(user);
        tokenA.mint(user,10000 ether);
        tokenB.mint(user,10000 ether);
        tokenC.mint(user,10000 ether);
        tokenA.approve(address(router),type(uint256).max);
        tokenB.approve(address(router),type(uint256).max);
        tokenC.approve(address(router),type(uint256).max);
        IUniswapV2Pair(pair1).approve(address(router),type(uint256).max);
        IUniswapV2Pair(pair2).approve(address(router),type(uint256).max);

        vm.stopPrank();
    }

    function testAddLiquidityToPair1()public {
        //test first add
        vm.startPrank(user);
        (,,liquidity) = router.addLiquidity(
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
        uint lpBalance = IUniswapV2Pair(pair1).balanceOf(user);
        assertEq(lpBalance, liquidity);
        assertEq(lpBalance, 414 ether);
        assertEq(reserveA,1000 ether);
        assertEq(reserveB,2000 ether);
        assertEq(tokenA.balanceOf(user),9000 ether);
        assertEq(tokenB.balanceOf(user),8000 ether);
        // liquidity = 414 ether;

        //test not first add
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
        
        assertEq(reserveA,2000 ether);
        assertEq(reserveB,4000 ether);
        assertEq(tokenA.balanceOf(user),8000 ether);
        assertEq(tokenB.balanceOf(user),6000 ether);

    }

    function testRemoveLiquidity()public {
        vm.startPrank(user);
        
        (amountA,amountB) = router.removeLiquidity(
            address(tokenA),
            address(tokenB),
            liquidity,
            0,
            0,
            user
        );
        
        uint lpAfter = IUniswapV2Pair(pair1).balanceOf(user);
        assertEq(lpAfter, 0);
        vm.stopPrank();
    }

    function swapExactTokensForTokens()public{
//给pair2添加流动性
        router.addLiquidity(
            address(tokenB),
            address(tokenC),
            1000 ether,
            2000 ether,
            1000 ether,
            2000 ether,
            user
        );

        vm.startPrank(user);
        router.swapExactTokensForTokens(100 ether,0,[address(tokenA),address(tokenB),address(tokenC)], to);
        vm.stopPrank();
//验证语句
        
    }

    function swapTokensForExactTokens()public{
        vm.startPrank(user);
        router.swapTokensForExactTokens(100 ether,0,[address(tokenA),address(tokenB),address(tokenC)], to);
        vm.stopPrank();
//验证语句
        
    }
}
