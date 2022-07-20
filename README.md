# Triswap
an opinionated, uniswap-style AMM for a wider range of token standards (erc20, 721s, and 1155s)

## About

Over the last year, we have seen an emerging class of "fungible" nfts: 1 of many editions,
in-game items, token gated DAOs + events, floors of popular collections, 
and 1155s, to name a few. While order books allow for exchanges to happen, liquidity
is sparce and equilibrium prices are difficult to find. For the NFT space to continue to 
grow, their trading mechanisms must also evolve.

This is a first step at doing that, and provides base functionality for a 
proof-of-concept AMM offering any combination of ERC20, ERC721, and ERC1155 pairs.

## Fungibility requirements + mechanism

Currently, ERC721s within the same collection, and ERC1155s within the same collection and
ID are considered "fungible". It is up to the LPer to determine if his/her 721 possesses
any additional rarity traits that might discourage this type of fungibility. During swaps,
an arbitrary batch of 721s from the collection is distributed to the user. It is worth
noting that only 1155s with IDs < 2^88 are currently supported. While potentially limiting,
this ensures that all relevant token data (address, token type, optional id) can be stored
in a singular storage slot. Additional 1155 considerations included whether all NFTs within
a collection should be fungible, or just those with the same IDs. 
Ultimately, the former felt more intuitive.

## Acknowledgements

1) Obviously heavily inspired by [Uniswap V2](https://github.com/Uniswap/v2-core)

2) Small techincal decisions also based off of [Seaport](https://github.com/ProjectOpenSea/seaport) 
and [Sudoswap](https://github.com/sudoswap/lssvm), leading players in advancing the NFT trading space

3) Built with [Foundry](https://github.com/foundry-rs/foundry)

## Additional thoughts

While NFT LPing may be an interest to some defi hobbyests, I see a more likely future
where NFT collections start natively on AMMs, removing the need for minting + secondary
trading entirely. This would allow for significanly more sustainable communities, where
quantity and pricing would be determined entirely on market demand.

## Next steps + future changes

This is a very preliminary first implementation, and more of a thought experiment than
finished protocol

First, NFT-NFT swaps are currently "possible" but there is very little reason
for these to be used as currently implemented, unless the quantity of each pair
is sufficiently high. This has to do with minimum liquidity requirements and
potential rounding issues

Router implementation soon

More advanced LPing and trading characteristics for smaller collections, ability to select
721s, etc
