// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { IUniswapV2Factory } from './interfaces/IUniswapV2Factory.sol';
import { UniswapV2Pair, IUniswapV2Pair } from './UniswapV2Pair.sol';
import { TokenItemType, PoolToken, TokenPair } from './helpers/TokenStructs.sol';

contract UniswapV2Factory is IUniswapV2Factory {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    // mapping(address => mapping(address => TokenPair)) public getPair;
    address[] public allPairs;

    // event PairCreated(address indexed token0, address indexed token1, uint8 token0Type, uint8 token1Type, address pair, uint256);

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(
        PoolToken calldata tokenA, 
        PoolToken calldata tokenB
    ) external returns (address pair) {
        // currently doesnt allow for 1155 id1 <-> 1155 id2 swaps :(
        require(tokenA.tokenAddress != tokenB.tokenAddress, 'UniswapV2: IDENTICAL_ADDRESSES');
        // (PoolToken memory poolToken0, PoolToken memory poolToken1) = 
        //     tokenA < tokenB 
        //     ? (PoolToken({tokenAddress: tokenA, tokenItemType: TokenItemType(tokenAType), id: tokenAId}), PoolToken({tokenAddress: tokenB, tokenItemType: TokenItemType(tokenBType), id: tokenBId}))
        //     : (PoolToken({tokenAddress: tokenB, tokenItemType: TokenItemType(tokenBType), id: tokenBId}), PoolToken({tokenAddress: tokenA, tokenItemType: TokenItemType(tokenAType), id: tokenAId}));
        (PoolToken calldata poolToken0, PoolToken calldata poolToken1) = 
            tokenA.tokenAddress < tokenB.tokenAddress
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(poolToken0.tokenAddress != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[poolToken0.tokenAddress][poolToken1.tokenAddress] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        // require(getPair[poolToken0.tokenAddress][poolToken1.tokenAddress].pairAddress == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient

        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(poolToken0.tokenAddress, poolToken1.tokenAddress));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IUniswapV2Pair(pair).initialize(poolToken0, poolToken1);

        // no need to populate both sides
        getPair[poolToken0.tokenAddress][poolToken1.tokenAddress] = pair;
        // getPair[poolToken0.tokenAddress][poolToken1.tokenAddress] = TokenPair({
        //     token0: poolToken0,
        //     token1: poolToken1,
        //     pairAddress: pair
        // });

        allPairs.push(pair);
        emit PairCreated(
            poolToken0.tokenAddress,
            poolToken1.tokenAddress,
            pair, 
            uint8(poolToken0.tokenItemType),
            uint8(poolToken1.tokenItemType),
            poolToken0.id, // default to 0 for non-1155s 
            poolToken1.id, // default to 0 for non-1155s 
            allPairs.length
        );
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
