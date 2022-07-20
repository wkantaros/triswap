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
      token721.safeTransferFrom(address(this), p20to721, id);
      unchecked {
        ++i;
        ++id;
      }
    }
  }

  function testMint721() public {
    vm.expectEmit(true, false, false, false);
    ITriswapPair(p20to721).mint(address(this));
    // sqrt(100*1000000) - 10**3 = 9000
    assertEq(ITriswapPair(p20to721).balanceOf(address(this)),9000);
    (uint112 reserve20, uint112 reserve721,) = ITriswapPair(p20to721).getReserves();
    assertEq(reserve20, 1000000);
    assertEq(reserve721, 100);
  }

  function testMint1155() public {
    vm.expectEmit(true, false, false, false);
    ITriswapPair(p20to1155).mint(address(this));
    // sqrt(1000*1000000) is 31622 - 10**3 = 30622
    assertEq(ITriswapPair(p20to1155).balanceOf(address(this)),30622);
    (uint112 reserve20, uint112 reserve1155,) = ITriswapPair(p20to1155).getReserves();
    assertEq(reserve20, 1000000);
    assertEq(reserve1155, 1000);
  }

  function testSwap721for20() public {
    // user sells 10 nfts in return for 90,661 erc20 tokens
    ITriswapPair(p20to721).mint(address(this));
    MockERC721BatchMint(pt721.tokenAddress).batchMint(address(0xBEEF), 100, 10);
    vm.startPrank(address(0xBEEF));
    uint id = 100;
    for (uint i; i < 10;){
      MockERC721BatchMint(pt721.tokenAddress).transferFrom(address(0xBEEF), p20to721, id);
      unchecked {
        ++i;
        ++id;
      }
    }
    vm.stopPrank();
    ITriswapPair(p20to721).swap(
        90661, 0, address(0xBEEF), new bytes(0)
    );
    assertEq(MockERC20(pt20.tokenAddress).balanceOf(address(0xBEEF)), 90661);
  }

  function testSwap20for721() public {
    // NOTE: router must use safeTransferFrom in order to invoke onERC721Received
    // user sells 31021 erc20 tokens in exchange for 3 nfts
    ITriswapPair(p20to721).mint(address(this));
    MockERC20(pt20.tokenAddress).mint(address(0xBEEF), 31021);
    vm.prank(address(0xBEEF));
    MockERC20(pt20.tokenAddress).transfer(p20to721, 31021);
    ITriswapPair(p20to721).swap(
        0, 3, address(0xBEEF), new bytes(0)
    );
    assertEq(MockERC721BatchMint(pt721.tokenAddress).balanceOf(address(0xBEEF)), 3);
  }

  function testSwap1155for20() public {
    // send 1000 erc1155s for 90661 erc20 tokens in return 
    ITriswapPair(p20to1155).mint(address(this));
    MockERC1155(pt1155.tokenAddress).mint(address(0xBEEF), 88, 100, "");
    vm.prank(address(0xBEEF));
    MockERC1155(pt1155.tokenAddress).safeTransferFrom(address(0xBEEF), p20to1155, 88, 100, "");
    ITriswapPair(p20to1155).swap(
        90661, 0, address(0xBEEF), new bytes(0)
    );
    assertEq(MockERC20(pt20.tokenAddress).balanceOf(address(0xBEEF)), 90661);
  }

  function testSwap20for1155() public {
    // user sells 31021 erc20 tokens in exchange for 30 1155s of same ID
    ITriswapPair(p20to1155).mint(address(this));
    MockERC20(pt20.tokenAddress).mint(address(0xBEEF), 31021);
    vm.prank(address(0xBEEF));
    MockERC20(pt20.tokenAddress).transfer(p20to1155, 31021);
    ITriswapPair(p20to1155).swap(
        0, 30, address(0xBEEF), new bytes(0)
    );
    assertEq(MockERC1155(pt1155.tokenAddress).balanceOf(address(0xBEEF), 88), 30);
  }
  function testFailSwap721for20() public {
    // user sells 10 nfts in return for 90,661 erc20 tokens
    ITriswapPair(p20to721).mint(address(this));
    MockERC721BatchMint(pt721.tokenAddress).batchMint(address(0xBEEF), 100, 10);
    vm.startPrank(address(0xBEEF));
    uint id = 100;
    for (uint i; i < 10;){
      MockERC721BatchMint(pt721.tokenAddress).transferFrom(address(0xBEEF), p20to721, id);
      unchecked {
        ++i;
        ++id;
      }
    }
    vm.stopPrank();
    ITriswapPair(p20to721).swap(
        90662, 0, address(0xBEEF), new bytes(0)
    );
    assertEq(MockERC20(pt20.tokenAddress).balanceOf(address(0xBEEF)), 90662);
  }

  function testFailSwap20for721() public {
    // NOTE: router must use safeTransferFrom in order to invoke onERC721Received
    // user sells 31021 erc20 tokens in exchange for 3 nfts
    ITriswapPair(p20to721).mint(address(this));
    MockERC20(pt20.tokenAddress).mint(address(0xBEEF), 31021);
    vm.prank(address(0xBEEF));
    MockERC20(pt20.tokenAddress).transfer(p20to721, 31021);
    ITriswapPair(p20to721).swap(
        0, 4, address(0xBEEF), new bytes(0)
    );
    assertEq(MockERC721BatchMint(pt721.tokenAddress).balanceOf(address(0xBEEF)), 4);
  }

  function testFailSwap1155for20() public {
    // send 1000 erc1155s for 90661 erc20 tokens in return 
    ITriswapPair(p20to1155).mint(address(this));
    MockERC1155(pt1155.tokenAddress).mint(address(0xBEEF), 88, 100, "");
    vm.prank(address(0xBEEF));
    MockERC1155(pt1155.tokenAddress).safeTransferFrom(address(0xBEEF), p20to1155, 88, 100, "");
    ITriswapPair(p20to1155).swap(
        90662, 0, address(0xBEEF), new bytes(0)
    );
    assertEq(MockERC20(pt20.tokenAddress).balanceOf(address(0xBEEF)), 90662);
  }

  function testFailSwap20for1155() public {
    // user sells 31021 erc20 tokens in exchange for 30 1155s of same ID
    ITriswapPair(p20to1155).mint(address(this));
    MockERC20(pt20.tokenAddress).mint(address(0xBEEF), 31021);
    vm.prank(address(0xBEEF));
    MockERC20(pt20.tokenAddress).transfer(p20to1155, 31021);
    ITriswapPair(p20to1155).swap(
        0, 31, address(0xBEEF), new bytes(0)
    );
    assertEq(MockERC1155(pt1155.tokenAddress).balanceOf(address(0xBEEF), 88), 31);
  }
}