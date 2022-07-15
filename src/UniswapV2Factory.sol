// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { IUniswapV2Factory } from './interfaces/IUniswapV2Factory.sol';
import { UniswapV2Pair, IUniswapV2Pair } from './UniswapV2Pair.sol';
import { TokenItemType, PoolToken, TokenPair } from './libraries/TokenStructs';

contract UniswapV2Factory is IUniswapV2Factory {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, uint8 token0Type, uint8 token1Type, address pair, uint256);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(
        address tokenA, 
        address tokenB, 
        uint8 tokenAType, 
        uint8 tokenBType, 
        uint256 tokenAId,
        uint256 tokenBId
    ) external returns (address pair) {
        // currently doesnt allow for 1155 id1 <-> 1155 id2 swaps :(
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (PoolToken poolToken0, PoolToken poolToken1) = 
            tokenA < tokenB 
            ? PoolToken({tokenA, TokenItemType(tokenAType), tokenAId}), PoolToken({tokenB, TokenItemType(tokenBType), tokenBId})
            : PoolToken({tokenB, TokenItemType(tokenBType), tokenBId}), PoolToken({tokenA, TokenItemType(tokenAType), tokenAId});
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient

        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IUniswapV2Pair(pair).initialize(token0, token1);

        // no need to populate both sides
        getPair[token0][token1] = TokenPair({
            token0: token0Struct,
            token1: token1Struct,
            pairAddress: pair
        });

        allPairs.push(pair);
        emit PairCreated(
            token0.tokenAddress,
            token1.tokenAddress,
            pair, 
            token0.tokenItemType,
            token1.tokenItemType,
            token0.id, // default to 0 for non-1155s 
            token1.id, // default to 0 for non-1155s 
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
