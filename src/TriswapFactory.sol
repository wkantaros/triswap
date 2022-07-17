// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { ITriswapFactory } from './interfaces/ITriswapFactory.sol';
import { TriswapPair, ITriswapPair } from './TriswapPair.sol';
import { TokenItemType, PoolToken, TokenPair } from './helpers/TokenStructs.sol';


// UniswapV2Factory w new createpair criteria
contract TriswapFactory is ITriswapFactory {
    address public feeTo;
    address public feeToSetter;

    mapping(bytes32 => mapping(bytes32 => address)) public getPair;
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
        (PoolToken memory poolToken0, PoolToken memory poolToken1) = 
            tokenA.tokenAddress < tokenB.tokenAddress
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        bytes32 packedToken0 = packToken(poolToken0.tokenAddress, poolToken0.tokenItemType, poolToken0.id);
        bytes32 packedToken1 = packToken(poolToken1.tokenAddress, poolToken1.tokenItemType, poolToken1.id);
        require(packedToken0 != packedToken1, "duplicate tokens");
        require(poolToken0.tokenAddress != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[packedToken0][packedToken1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient

        bytes memory bytecode = type(TriswapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(packedToken0, packedToken1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ITriswapPair(pair).initialize(packedToken0, packedToken1);

        // no need to populate both sides
        getPair[packedToken0][packedToken1] = pair;

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

    function packToken(address tokenAddress, TokenItemType tokenType, uint88 id) public pure returns (bytes32 packed) {
        // only 1155s with id's < 2^88 currently supported 
        packed = bytes32(bytes20(tokenAddress)) 
            | (bytes32(bytes1(uint8(tokenType))) >> 160) 
            | (bytes32(bytes11(id)) >> 168);
    }

    function unpackToken(bytes32 packedToken) external pure returns (address tokenAddress, TokenItemType tokenType, uint88 id) {
        tokenAddress = address(uint160(bytes20(packedToken)));
        tokenType = TokenItemType(uint8(bytes1((packedToken << 160))));
        id = uint88(bytes11((packedToken << 168)));
    }
}
