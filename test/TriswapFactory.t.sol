// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { DSTest } from "ds-test/test.sol";
import { TriswapFactory } from "../src/TriswapFactory.sol"; 
import { TokenItemType, PoolToken } from "../src/helpers/TokenStructs.sol";
import { MockERC20 } from 'solmate/test/utils/mocks/MockERC20.sol';
import { MockERC721 } from 'solmate/test/utils/mocks/MockERC721.sol';
import { MockERC1155 } from 'solmate/test/utils/mocks/MockERC1155.sol';
import { Hevm } from './utils/Hevm.sol';

contract TriswapFactoryTest is DSTest {

  Hevm vm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

  TriswapFactory factory;
  PoolToken pt20;
  PoolToken pt721;
  PoolToken pt1155;

  function setUp() public {
    factory = new TriswapFactory(msg.sender);
    MockERC20 token20 = new MockERC20("test20", "T20", 18);
    MockERC721 token721 = new MockERC721("test20", "T20");
    MockERC1155 token1155 = new MockERC1155();
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
  }

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

  function testCreatePair20To721() public {
    vm.expectEmit(true, true, false, true);
    emit PairCreated(
            pt20.tokenAddress,
            pt721.tokenAddress,
            address(0xB3d54d965eCa1Cfb97c368Ce8B6eD58E6cA429E7), 
            uint8(TokenItemType.ERC20),
            uint8(TokenItemType.ERC721),
            0, // default to 0 for non-1155s 
            0, // default to 0 for non-1155s 
            1
        );
    factory.createPair(pt20, pt721);
  }


  function testCreatePair1155To721() public {
    vm.expectEmit(true, true, false, true);
    emit PairCreated(
            pt721.tokenAddress,
            pt1155.tokenAddress,
            address(0xb7aF60Db779652A5F57873Ffd4721cF918b42545), 
            uint8(TokenItemType.ERC721),
            uint8(TokenItemType.ERC1155),
            0, // default to 0 for non-1155s 
            88, // 88 for 1155 
            1
        );
    factory.createPair(pt1155, pt721);
  }

  function testPackUnpack1155Token() public {
    bytes32 packedToken = factory.packToken(pt1155.tokenAddress, pt1155.tokenItemType, pt1155.id);
    (address tk1155a, uint8 type1155, uint88 id) = factory.unpackToken(packedToken);
    assertEq(pt1155.tokenAddress, tk1155a);
    assertEq(uint8(pt1155.tokenItemType), type1155);
    assertEq(pt1155.id, id);
  }
}