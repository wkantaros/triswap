// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

enum TokenItemType {
  ERC20,
  ERC721,
  ERC1155
}

struct PoolToken {
  address tokenAddress;
  TokenItemType tokenItemType;
  uint88 id; // needed for 1155 transfers 
}

struct TokenPair {
  PoolToken token0;
  PoolToken token1;
  address pairAddress;
}
