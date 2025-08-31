// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "./interfaces/IUniswapV2Pair.sol";

interface AutomationCompatibleInterface {
    function checkUpKeep(bytes calldata checkData)external returns(bool upKeepNeeded,bytes memory performData);
    function performUpKeep(bytes calldata performData)external;
}

contract DynamicFeeManage is AutomationCompatibleInterface{

    address[] public allPairs; 
    mapping(address => uint256)public feeForPair;
    uint public lastTimeStamp;
    uint public interval;

    constructor(){
        interval = 1 hours;
        lastTimeStamp = block.timestamp;

    }

    function checkUpKeep(bytes calldata checkData)external view override returns(bool upKeepNeeded,bytes memory performData){
        upKeepNeeded = (block.timestamp - lastTimeStamp) >= interval;
        
    }

    function performUpKeep(bytes calldata performData)external override{
        upDataFeeForPairs();
    }
    
    function addPair(address pair)external {
        allPairs.push(pair);
        feeForPair[pair] = 3;

    }

    function firstSetFee(address pair)public {
        feeForPair[pair] = 3;
    }

    function upDataFeeForPairs()public {
        for(uint256 i = 0;i < allPairs.length;i++){
            feeForPair[allPairs[i]] = upDataFeeForPair(allPairs[i]);

        }
    }
    
    function upDataFeeForPair(address pair)internal returns(uint256 fee){
        //将pair的数据和chainlink数据发送到链下javascript(如何发到链下再发回来)
        //调用链下javascript计算波动率和费率再发回来(如何调用链下)
        //IUniswapV2Pair(pair).updataFee(newFee);

    }

}