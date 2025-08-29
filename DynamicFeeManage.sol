// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "./interfaces/IUniswapV2Pair.sol";

contract DynamicFeeManage {

    
    address[] public allPairs; 
    mapping(address => uint256)public feeForPair;

    function addPair(address pair)external {
        allPairs.push(pair);
    }
    
    function checkUpKeep()public {}

    function performUpKeep()public {}

    function upDataFeeForPairs()public {
        for(uint256 i = 0;i < allPairs.length;i++){
            feeForPair[allPairs[i]] = upDataFeeForPair(allPairs[i]);

        }
    }
    
    function upDataFeeForPair(address pair)internal returns(uint256 fee){
        
        //IUniswapV2Pair(pair).updataFee(newFee);

    }

}