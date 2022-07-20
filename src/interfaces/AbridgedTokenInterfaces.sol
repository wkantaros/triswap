// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function transfer(
        address to,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address) external view returns (uint256);
}

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external;

    function balanceOf(address) external view returns (uint256);
}

interface IERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function balanceOf(address, uint256) external view returns (uint256);
}

interface IBalanceOf {
    function balanceOf(address) external view returns (uint256);
}