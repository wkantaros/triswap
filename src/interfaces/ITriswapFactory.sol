// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { PoolToken, TokenPair } from 'src/helpers/TokenStructs.sol';

// IUniswapV2Factory w minor adjustments
interface ITriswapFactory {
    event PairCreated(
        address indexed token0, 
        address indexed token1, 
        address pair, 
        uint8 token0Type, 
        uint8 token1Type, 
        uint256 token0Id, 
        uint256 token1Id, 
        uint256 length
    );

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(bytes32 token0, bytes32 token1) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(
        PoolToken calldata tokenA,
        PoolToken calldata tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
