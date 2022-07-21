# Triswap
an opinionated, Uniswap-style AMM for a wider range of token standards (erc20s, 721s, and 1155s)

## About

Ironically, there's been an emerging class of "fungible" nfts. 
These include one-of-many editions, in-game items, token-gated DAOs + events,
floors of popular collections, and 1155s as a class, to name a few.

While order books allow for basic trading, liquidity is sparce and equilibrium prices
are difficult to find. As the NFT space moves away from just PFPs, new trading mechanisms
can be implemented to help fix these issues.

This is a first step in doing that, and provides base functionality for a 
proof-of-concept AMM offering any combination of `ERC20`, `ERC721`, and `ERC1155` pairs.

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

## Additional thoughts

While NFT LPing may be an interest to some defi hobbyists, I see a more likely future
where NFT collections start natively on AMMs, removing the need for minting + order books
entirely. This would create significanly more sustainable communities, where
quantity and pricing are determined entirely on market demand.

Current examples have primarily been single-sided liquidity bonding curves, such as 
Uniswap's [Unisocks](https://unisocks.exchange/), Decent's [Crescendo](https://mirror.xyz/0xBAfb15bF152365bd344639b6eDe5Dec09d5Ba64E/vO6w0X-fRibvaPSrJU1UBdCnC_kNps6jOCK3kbWnyTk), and Glass's [Prism](https://glass.xyz/v/SVt0Ea518b5fG_FS4fxMZ0Kq8vwlVkdxl1JrVcLXhZw=)

## Acknowledgements

1) Obviously heavily inspired by [Uniswap V2](https://github.com/Uniswap/v2-core)

2) Some techincal decisions inspired by [Seaport](https://github.com/ProjectOpenSea/seaport) 
and [Sudoswap](https://github.com/sudoswap/lssvm), leading players in advancing the NFT trading space

3) Built with [Foundry](https://github.com/foundry-rs/foundry)


## Next steps + future changes

This is a very preliminary first implementation, and more of a thought experiment than
a finished protocol

While `ERC721` to `ERC721` swaps are possible, there is very little reason to use them
as currently implemented, due to minimum liquidity requirements and potential rounding issues.
More advanced LPing and trading characteristics for smaller collections, ability to select
721s, etc

Router implementation soon


