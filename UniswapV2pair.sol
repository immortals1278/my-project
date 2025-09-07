// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
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

interface AutomationCompatibleInterface {
    function checkUpKeep(bytes calldata checkData)external returns(bool upKeepNeeded,bytes memory performData);
    function performUpKeep(bytes calldata performData)external;
}

interface IERC20 {
    function balanceOf(address) external returns (uint256);

    function transfer(address to, uint256 amount) external;
}

contract UniswapV2Pair is ERC20,Math,AutomationCompatibleInterface {


    struct priceData{
        uint256 price;
        uint256 timeStamp;
    }
    priceData[] public priceHistory;
    uint256 public nextIndex;
    uint256 public bufferSize;
    bool public bufferFull;
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
    address public owner;

    event Mint(address indexed sender,uint256 amount0,uint256 amount1);
    event Burn(address indexed sender,uint256 amount0,uint256 amount1,address to);
    event Swap(address indexed sender,uint256 amount0,uint256 amount1,address indexed to);
    event PriceUpdate(uint256 price,uint256 timeStamp);

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
        priceHistory = new priceData[](bufferSize);
    }

    function initialize(address _token0,address _token1) public{
        if (token0 != address(0) || token1 != address(0)){

            revert alreadyInitialized();
        }
        token0 = _token0;
        token1 = _token1;

        fee = 3;
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

        if(totalSupply == o){
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

    function burn(addressto) public returns(uint256 amount0,uint256 amount1){
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
        
        uint256 balanceAdjusted0 = (balance0 * 1000) - (amount0in * fee);
        uint256 balanceAdjusted1 = (balance1 * 1000) - (amount1in * fee);

        if (balanceAdjusted0 * balanceAdjusted1 <uint256(reserve0) * uint256(reserve1) * (1000**2)) revert Invalidk();

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
                uint256 twap = uint256(UQ112x112.encode(reserve1).uqdiv(reserve0))//数值为连续两次交易间的twap
                price0CumulativeLast += twap * timeElapsed;
                price1CumulativeLast += uint256(UQ112x112.encode(reserve0).uqdiv(reserve1)) * timeElapsed;
                
                priceHistory[nextIndex] = price(twap,block.timestamp);
                emit PriceUpdate(twap,block.timestamp);
                nextIndex = (nextIndex + 1) % bufferSize;

                if (nextIndex == 0 && !bufferFull){
                    bufferFull = true;
                }
                }

        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = uint32(block.timestamp);
        emit Sync(reserve0,reserve1);
    }


    function updataFee(uint256 newFee)public {
        fee = newFee;
    }

    function getPriceCount()public view returns(uint256){
        return bufferFull ? bufferSize : nextIndex;
    }



    function _safeTransfer(address token,address to,uint256 value) private {
        (bool success,bytes memory data) = token.call(abi.encodeWithSignature("transfer(address,uint156)",to,value));
        if(!success|| (data.Length != 0 && !abi.decode(data,(bool)))){
            revert TransferFailed();
        }
    }



    
}
