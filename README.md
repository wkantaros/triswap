# Triswap
an opinionated, uniswap-style AMM for a wider range of token standards (erc20, 721s, and 1155s)

## About

Ironically, we have seen an emerging class of "fungible" nfts. These include one-of-many editions,
in-game items, token-gated DAOs + events, floors of popular collections, 
and 1155s as a class, to name a few.

While order books allow for basic trading, liquidity is sparce and equilibrium prices
are difficult to find. As the "fungible" NFT space continues to grow, new trading mechanisms
can be must solved to increase liqudity and establish fair pricing.

This is a first step in doing that, and provides base functionality for a 
proof-of-concept AMM offering any combination of`ERC20`, `ERC721`, and `ERC1155` pairs.

## Fungibility requirements + mechanism

Currently, `ERC721` collections, `ERC1155` collections of a particular ID, and `ERC20`s are are
considered "fungible". It is up to the LPer to determine if their `ERC721` possesses
any additional rarity traits that might discourage this type of fungibility. 

During swaps, an arbitrary batch of 721s from the collection is distributed to the user. It is worth
noting that only 1155s with IDs < 2^88 are currently supported. While potentially limiting,
this ensures that all relevant token data (`address tokenAddress`, `uint8 tokenItemType`, `uint88 optionalId`) can be placed
in a single storage slot. Additional 1155 considerations included whether all NFTs within a collection 
should be fungible, or just those with the same IDs. Ultimately, the former felt more intuitive.

A `tokenItemType` can be `ERC20`, `ERC721`, or `ERC1155` 

A `triswapPair` can be any combination of two `tokenItemType`s

## Acknowledgements

1) Obviously heavily inspired by [Uniswap V2](https://github.com/Uniswap/v2-core)

2) Some techincal decisions inspired by [Seaport](https://github.com/ProjectOpenSea/seaport) 
and [Sudoswap](https://github.com/sudoswap/lssvm), leading players in advancing the NFT trading space

3) Built with [Foundry](https://github.com/foundry-rs/foundry)

## Additional thoughts

While NFT LPing may be an interest to some defi hobbyests, I see a more likely future
where NFT collections start natively on AMMs, removing the need for minting + secondary
trading entirely. This would allow for significanly more sustainable communities, where
quantity and pricing would be determined entirely on market demand.

## Next steps + future changes

This is a very preliminary first implementation, and more of a thought experiment than
a finished protocol

First, `ERC721` to `ERC721` swaps are currently possible, but there is very little reason
for these to be used as currently implemented, unless the quantity of each pair
is sufficiently high. This has to do with minimum liquidity requirements and
potential rounding issues

Router implementation soon

More advanced LPing and trading characteristics for smaller collections, ability to select
721s, etc
