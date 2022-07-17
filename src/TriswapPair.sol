// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { ITriswapPair } from './interfaces/ITriswapPair.sol';
import { ERC20 } from 'solmate/tokens/ERC20.sol';
import { Math } from './lib/Math.sol';
import { UQ112x112 } from './lib/UQ112x112.sol';
import { IUniswapV2Factory } from './interfaces/IUniswapV2Factory.sol';
import { IUniswapV2Callee } from './interfaces/IUniswapV2Callee.sol';
import { IERC20, IERC721, IERC1155 } from './interfaces/AbridgedTokenInterfaces.sol';
import { TokenItemType, PoolToken } from './helpers/TokenStructs.sol';
import { TokenTransferrer } from './helpers/TokenTransferrer.sol';

contract TriswapPair is ITriswapPair, TokenTransferrer, ERC20 {
    using UQ112x112 for uint224;

    uint256 public constant MINIMUM_LIQUIDITY = 10**3;

    address public factory;
    bytes32 private token0;   // accessible via unpackToken
    bytes32 private token1;   // accessible via unpackToken

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint256[] private idSetToken0;
    uint256[] private idSetToken1;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function unpackToken0() external view returns (PoolToken memory) {
       return  _unpackToken(token0);
    }

    function unpackToken1() external view returns (PoolToken memory) {
        return _unpackToken(token0);
    }

    function _safeTransfer(PoolToken memory token, address to, uint value) private {
        require(value > 0, "token transfer value 0");
        if (token.tokenItemType == TokenItemType.ERC20) {
            _performERC20Transfer(token.tokenAddress, address(this), to, value);
        } else if (token.tokenItemType == TokenItemType.ERC1155) {
            _performERC1155Transfer(token.tokenAddress, address(this), to, uint256(token.id), value);
        } else {
            // transfer any nfts of collection
            uint256[] storage idSet = (token.tokenAddress == _address(token0)) ? idSetToken0 : idSetToken1;
            
            require(idSet.length >= value, "insufficient balance");
            uint256 lastIndex = idSet.length - 1;
            for (uint i; i < value;){
                uint id = idSet[lastIndex];
                _performERC721Transfer(token.tokenAddress, address(this), to, id);
                idSet.pop();
                unchecked {
                    --lastIndex;
                    ++i;
                }
            }
        }
    }

    constructor() ERC20("Triswap", "Tri", 18){
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(bytes32 _token0, bytes32 _token1) external {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, 'UniswapV2: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(_reserve0) * uint256(_reserve1));
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply * (rootK - rootKLast);
                    uint256 denominator = (rootK * 5) + rootKLast;
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    function _getBalanceOf(PoolToken memory poolToken, address owner) private view returns (uint256) {
        if (poolToken.tokenItemType == TokenItemType.ERC20) {
            return IERC20(poolToken.tokenAddress).balanceOf(owner);
        } else if (poolToken.tokenItemType == TokenItemType.ERC721) {
            return IERC721(poolToken.tokenAddress).balanceOf(owner);
        } else {
            return IERC1155(poolToken.tokenAddress).balanceOf(owner, uint256(poolToken.id));
        }
    }

    function _unpackToken(bytes32 packedToken) private pure returns (PoolToken memory) {
        return PoolToken({
            tokenAddress: _address(packedToken),
            tokenItemType: TokenItemType(uint8(bytes1((packedToken << 160)))),
            id: uint88(bytes11((packedToken << 168)))
        });
    }

    function _address(bytes32 packedToken) private pure returns (address tokenAddress) {
       tokenAddress = address(uint160(bytes20(packedToken)));
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        PoolToken memory _token0 = _unpackToken(token0);
        PoolToken memory _token1 = _unpackToken(token1);
        uint256 balance0 = _getBalanceOf(_token0, address(this));
        uint256 balance1 = _getBalanceOf(_token1, address(this));
        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0 * _totalSupply / _reserve0, amount1 * _totalSupply / _reserve1);
        }
        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0) * uint256(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint256 amount0, uint256 amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        PoolToken memory _token0 = _unpackToken(token0);
        PoolToken memory _token1 = _unpackToken(token1);
        uint256 balance0 = _getBalanceOf(_token0, address(this));
        uint256 balance1 = _getBalanceOf(_token1, address(this));
        uint256 liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity * balance0 / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity * balance1 / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = _getBalanceOf(_token0, address(this));
        balance1 = _getBalanceOf(_token1, address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0) * uint256(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        PoolToken memory _token0 = _unpackToken(token0);
        PoolToken memory _token1 = _unpackToken(token1);
        require(to != _token0.tokenAddress && to != _token1.tokenAddress, 'UniswapV2: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        balance0 = _getBalanceOf(_token0, address(this));
        balance1 = _getBalanceOf(_token1, address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance0Adjusted = (balance0 * 1000) - (amount0In * 3);
        uint balance1Adjusted = (balance1 * 1000) - (amount1In * 3);
        require(balance0Adjusted * balance1Adjusted >= uint256(_reserve0) * uint256(_reserve1) * (1000**2), 'UniswapV2: K');
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        PoolToken memory _token0 = _unpackToken(token0);
        PoolToken memory _token1 = _unpackToken(token1);
        _safeTransfer(_token0, to, _getBalanceOf(_token0, address(this)) - reserve0);
        _safeTransfer(_token1, to, _getBalanceOf(_token1, address(this)) - reserve1);
    }

    // force reserves to match balances
    function sync() external lock {
        _update(_getBalanceOf( _unpackToken(token0), address(this)), _getBalanceOf( _unpackToken(token1), address(this)), reserve0, reserve1);
    }

    // add id to arr if nft of collection
    // no duplicates since 1 id per collection
    function onERC721Received(
        address,
        address,
        uint256 id,
        bytes memory
    ) public virtual returns (bytes4) {
        // If it's from the pair's NFT, add the ID to respective array
        if (msg.sender == _address(token0)) {
            idSetToken0.push(id);
        } else if (msg.sender == _address(token1)) {
            idSetToken1.push(id);
        }
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}
