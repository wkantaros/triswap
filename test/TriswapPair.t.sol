// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { DSTest } from "ds-test/test.sol";
import { TriswapFactory } from "../src/TriswapFactory.sol"; 
import { ITriswapPair } from "../src/interfaces/ITriswapPair.sol"; 
import { TokenItemType, PoolToken } from "../src/helpers/TokenStructs.sol";
import { MockERC20 } from 'solmate/test/utils/mocks/MockERC20.sol';
import { MockERC721BatchMint } from './utils/MockERC721BatchMint.sol';
import { MockERC1155 } from 'solmate/test/utils/mocks/MockERC1155.sol';
import { ERC1155TokenReceiver } from 'solmate/tokens/ERC1155.sol';
import { Hevm } from './utils/Hevm.sol';

contract TriswapPairTest is DSTest, ERC1155TokenReceiver{
  Hevm vm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

  TriswapFactory factory;
  address p20to721;
  address p20to1155;

  PoolToken pt20;
  PoolToken pt721;
  PoolToken pt1155;

  MockERC20 token20;
  bytes32 packed20;
  bytes32 packed1155;
  bytes32 packed721;

  function setUp() public {
    factory = new TriswapFactory(address(this));
    token20 = new MockERC20("test20", "T20", 18);
    MockERC721BatchMint token721 = new MockERC721BatchMint("test20", "T20");
    MockERC1155 token1155 = new MockERC1155();
    token20.mint(address(this), 2000000);
    token1155.mint(address(this), 88, 100000, "");
    token721.batchMint(address(this), 0, 100);
    pt20 = PoolToken({
      tokenAddress: address(token20),
      tokenItemType: TokenItemType.ERC20,
      id: 0
    });

    pt721= PoolToken({
      tokenAddress: address(token721),
      tokenItemType: TokenItemType.ERC721,
      id: 0
    });

    pt1155 = PoolToken({
      tokenAddress: address(token1155),
      tokenItemType: TokenItemType.ERC1155,
      id: 88
    });
    factory.createPair(pt20, pt721);
    factory.createPair(pt20, pt1155);

    packed20 = factory.packToken(pt20.tokenAddress, pt20.tokenItemType, pt20.id);
    packed721 = factory.packToken(pt721.tokenAddress, pt721.tokenItemType, pt721.id);
    packed1155 = factory.packToken(pt1155.tokenAddress, pt1155.tokenItemType, pt1155.id);
    p20to721 = factory.getPair(packed20, packed721);
    p20to1155 = factory.getPair(packed20, packed1155);

    token20.transfer(p20to721, 1000000);
    token20.transfer(p20to1155, 1000000);
    token1155.safeTransferFrom(address(this), p20to1155, 88, 1000, "");

    uint id = 0;
    for (uint i; i < 100;){
      token721.transferFrom(address(this), p20to721, id);
      unchecked {
        ++i;
        ++id;
      }
    }
  }

  // function testMint721() public {
  // }

  // function testMint1155() public {
  // }


  // function testSwap721() public {
  // }

  // function testSwap1155() public {
  // }
}