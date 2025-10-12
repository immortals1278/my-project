// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

interface IUniswapV2Pair{
    function initialize(address,address) external;

    function getReserves()external returns(uint112,uint112,uint32);

    function mint(address) external returns(uint256);

    function burn(address) external returns(uint256,uint256);

    //有个transform方法我没写

    function swap(uint256,uint256,address,bytes calldata)external;

    function updatePrice()external;

    function updateFee()external returns(uint256);

    function getFee()external view returns(uint256);

}