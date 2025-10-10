// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./libraries/UQ112x112.sol";
import "./libraries/Math.sol";
import "./interfaces/IUniswapV2Callee.sol";

error alreadyInitialized();
error InsufficientLiquidityMintedError();
error InsufficientLiquidityBurnedError();
error InsufficientOutputAmount();
error InsufficientInputAmount();
error InsufficientLiquidity();
error Invalidk();
error TransferFailed();
error BalanceOverflow();


interface IERC20 {
    function balanceOf(address) external returns (uint256);

    function transfer(address to, uint256 amount) external;
}

contract UniswapV2Pair is ERC20,Math{


    uint256 public k;
    uint256 constant ONE;
    uint256 public sum0;
    uint256 public sumSq0;
    uint256 public sum;
    uint256 public sumSq;
    uint256 public priceCount;
    AggregatorV3Interface internal priceFeed;
    struct priceData{
        uint256 price;
        uint256 timeStamp;
    }
    priceData[] public priceHistoryOut;
    uint256 public nextIndexOut;
    uint256 public bufferSizeOut;
    bool public bufferFullOut;
    uint256 MINIMUM_LIQUIDITY = 1000;
    address public token0;
    address public token1;
    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    bool private isEntered;
    uint256 public fee;
    uint256 public feeMaxAdd;
    uint256 public baseFee;
    uin256 public oldPrice;
    address public owner;

    event Mint(address indexed sender,uint256 amount0,uint256 amount1);
    event Burn(address indexed sender,uint256 amount0,uint256 amount1,address to);
    event Swap(address indexed sender,uint256 amount0,uint256 amount1,address indexed to);
    event PriceUpdate(uint256 price,uint256 timeStamp);
    event sync(uint112 reserve0,uint112 reserve1);
    event newPrice(uint256);

    modifier nonReentrant(){
        require(!isEntered);
        isEntered = true;
        _;

        isEntered = false;
    }//防止重入攻击

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor () ERC20("uniswapV2 Pair", "UNIV2", 18){
        bufferSize = 50;
        bufferSizeOut = 24;
        priceHistoryOut = new priceData[](bufferSizeOut);
        fee = 3e15;
        feeMaxAdd = 7e15;
        k = 1e18;
        ONE = 1e18;
        baseFee = 3e15;
    }

    function initialize(address _token0,address _token1,address _priceFeed) public{
        if (token0 != address(0) || token1 != address(0)){

            revert alreadyInitialized();
        }
        token0 = _token0;
        token1 = _token1;
        priceFeed = AggregatorV3Interface(_priceFeed);

        
    }

    function getReserves() public view returns(uint112,uint112,uint32){
        return(reserve0,reserve1,blockTimestampLast);
    }

    function mint(address to) public returns(uint256 liquidity){
        (uint256 reserve0,uint256 reserve1) = getReserves();
        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - reserve0;
        uint256 amount1 = balance1 - reserve1;

        if(totalSupply == 0){
            liquidity = Math.sqrt(amount0*amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0),MINIMUM_LIQUIDITY);

        }else {
            liquidity = Math.min(
                (amount0*totalSupply)/reserve0,
                (amount1*totalSupply)/reserve1
            );}
        if(liquidity == 0){
            revert InsufficientLiquidityMintedError();
        }
        _mint(to,Liquidity);

        _update(balance0, balance1, reserve0, reserve1);

        emit Mint(to,amount0,amount1);
        
    }

    function burn(address to) public returns(uint256 amount0,uint256 amount1){
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 Liquidity = balanceOf[address(this)];
        amount0 = (Liquidity*balance0)/totalSupply;
        amount1 = (Liquidity*balance1)/totalSupply;
        if(amount0 == 0 ||amount1 == 0){
            revert InsufficientLiquidityBurnedError();
        }

        _burn(msg.sender,Liquidity);

        _safeTransfer(token0,to,amount0);
        _safeTransfer(token1,to,amount1);

        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));

        (uint112 reserve0,uint112 reserve1) = getReserves();
        _update(balance0,balance1,reserve0,reserve1);

        emit Burn(msg.sender,amount0,amount1,to);

    }

    function swap(uint256 amount0out,uint256 amount1out,address to,bytes calldata data) public nonReentrant{
        if (amount0out == 0 && amount1out == 0 ) revert InsufficientOutputAmount();
        
        (uint112 reserve0,uint112 reserve1) = getReserves();
        
        if (amount0out > reserve0 || amount1out > reserve1) revert InsufficientLiquidity();

        if (amount0out > 0) _safeTransfer(token0,to,amount0out);
        if (amount1out > 0) _safeTransfer(token1,to,amount1out);

        if (data.length > 0 ){
            IUniswapV2callee(to).uniswapV2call(
                msg.sender,
                amount0out,
                amount1out,
                data
            );
        }

        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0in = balance0 > reserve0 - amount0Out
            ? balance0 - (reserve0 - amount0Out)
            : 0;
        uint256 amount1in = balance1 > reserve1 - amount1Out
            ? balance1 - (reserve1 - amount1Out)
            : 0;
        if (amount0in == 0 && amount1in == 0) revert InsufficientInputAmount();
        
        uint256 balanceAdjusted0 = balance0 - (amount0in * fee / ONE);
        uint256 balanceAdjusted1 = balance1 - (amount1in * fee / ONE);

        if (balanceAdjusted0 * balanceAdjusted1 <uint256(reserve0) * uint256(reserve1)) revert Invalidk();

        _update(balance0,balance1,reserve0,reserve1);

        emit Swap(msg.sender,amount0out,amount1out,to);

    }

    function sync() public{
        balance0 = IERC20(token0).getBalance(address(this));
        balance1 = IERC20(token1).getBalance(address(this));
        (uint112 reserve0,uint112 reserve1) = getReserve();

        _updata(
            balance0 = IERC20(token0).getBalance(address(this)),
            balance1 = IERC20(token1).getBalance(address(this)),
            reserve0,
            reserve1
        );
    }

    function _updata(uint256 balance0,uint256 balance1,uint112 reserve0,uint112reserve1) private{
        if(balance0 > type(uint112).max || balance1 > type(uint112).max){
            revert BalanceOverflow();
        }

        unchecked{
            uint32 timeElapsed = uint32(block.timestamp) - blockTimestampLast;

            if(timeElapsed > 0 && reserve0 > 0 && reserve1 > 0){
                uint256 priceIn = uint256(UQ112x112.encode(reserve1).uqdiv(reserve0));//数值为连续两次交易间的twap
                price0CumulativeLast += priceIn * timeElapsed;
                price1CumulativeLast += uint256(UQ112x112.encode(reserve0).uqdiv(reserve1)) * timeElapsed;
                uint256 twap = (priceIn * 1e18) >> 112;
                emit newPrice(twap);//发到链下
                if(priceCount < 60){priceCount++;}//更新列表长度
                sum = sum + twap -oldPrice;
                sumSq = (sumSq + twap * twap - oldPrice * oldPrice) / ONE; 

                }

        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = uint32(block.timestamp);
        emit Sync(reserve0,reserve1);
        }
    }

    function callback(uint256 _oldPrice)external {
        oldPrice = _oldPrice;
    }

    function getPriceCount()public view returns(uint256){
        return priceCount;
    }

    function getMean()public view returns(uint256){
        uint256 count = getPriceCount();
        return sum / count;
    }

    function getCV()public view returns(uint256){
        uint256 mean = getMean();
        uint256 count = getPriceCount();
        uint256 var = sumSq / count - (mean * mean / ONE);
        uint256 std = sqrt(var) * 1e9;
        return (std * ONE) / mean;

    }


    function _safeTransfer(address token,address to,uint256 value) private {
        (bool success,bytes memory data) = token.call(abi.encodeWithSignature("transfer(address,uint156)",to,value));
        if(!success|| (data.Length != 0 && !abi.decode(data,(bool)))){
            revert TransferFailed();
        }
    }

    function getLatestPrice()public view returns(int256){
        (   
            uint80 roundID,         
            int256 price,          
            uint256 startedAt,      
            uint256 updatedAt,      
            uint80 answeredInRound
            ) = priceFeed.latestRoundData();
            return price;
    }//外部

    function getDecimals()public view returns(uint8){
        return priceFeed.decimals();
    }//外部

    function updatePrice()public {
        uint256 priceOut = getLatestPrice();
        uint256 decimals = getDecimals();
        uint256 price = priceOut * (10**(18 - decimals));
        sum0 = sum0 + price -priceHistoryOut[nextIndexOut].price;
        sumSq0 = sumSq0 + price * price - priceHistoryOut[nextIndexOut].price * priceHistoryOut[nextIndexOut].price;
        priceHistoryOut[nextIndexOut] = priceData{price:price,timeStamp:block.timestamp};
        nextIndexOut = (nextIndexOut + 1) % bufferSizeOut;
        if (nextIndexOut == 0 && !bufferFullOut){
            bufferFullOut = true;
        }
        
    }//外部

    function getPriceOutCount()public view returns(uint256){
        return bufferFullOut ? bufferSizeOut : nextIndexOut;
    }//外部

    function getMeanOut()public view returns(uint256){
        uint256 count = getPriceOutCount();
        return sum0 / count;
    }

    function getCVOut()public view returns(uint256){
       uint256 mean = getMeanOut();
        uint256 count = getPriceOutCount();
        uint256 var = sumSq0 / count - (mean * mean / ONE);
        uint256 std = sqrt(var) * 1e9;
        return (std * ONE) / mean;
    }

    function updataFee()public returns(uint256){
        uint256 cvIn = getCV();
        uint256 cvOut = getCVOut();
        cvCombined = cvIn * 3e17 + cvOut * 7e17;
        uint256 delta = k * cvCombined / ONE;
        if(delta > feeMaxAdd){
            delta = feeMaxAdd;
        }
        fee = baseFee + delta;
        return fee;
    }

    function getFee()public view returns(uint256){
        return fee;
    }
    
}
