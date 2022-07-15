pragma solidity ^0.8.7;

interface IUniswapV2Factory {
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

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA, 
        address tokenB, 
        uint8 tokenAType, 
        uint8 tokenBType, 
        uint256 tokenAId,
        uint256 tokenBId
    ) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
