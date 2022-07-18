# Triswap
opinionated uniswap-style AMM for larger range of token standards (erc20, 721s, and 1155s)

### about

As the NFT space grow, the mechanisms with whcih they transact must also evolve.
Over the last year, we have seen an emerging class of "fungible" nfts, such as
edition nfts, nft-gated DAOs + communities, in-game items, floors of popular
collections, and 1155s. With insufficient liquidity in the market for most
NFTs to ever be traded, AMMs are necessary to improve the quality of the ecosystem.

This is a first step at doing that, by provides proof-of-concept base functionality
for AMM style trading of any combination of ERC20, ERC721, and ERC1155 pairs.

### fungibility requirements + mechanism

Currently, ERC721s of the same contract, and ERC1155s of the same contract and ID
are considered "fungible". It is up to the LPer to determine if his/her 721 possesses
any additional rarity traits that might discourage this type of trading. Upon swaps,
an arbitrary batch of 721s from the collection is distributed to the user. It is worth
noting that only 1155s with IDs < 2^88 are currently supported. While potentially a
concern, this ensures that all PoolToken data can be stored in a singular storage slot.


### acknowledgements

Obviously heavily inspired by [Uniswap V2](https://github.com/Uniswap/v2-core)

Small techincal decisions also based off of [Seaport](https://github.com/ProjectOpenSea/seaport) and [Sudoswap](https://github.com/sudoswap/lssvm), leading players in advancing the NFT trading space


### next steps + future changes

This is very preliminary first implementation, and there are additional steps
needed to ensure proper functionality

First, NFT-NFT swaps are currently "possible" but there is very little reason
for these to be used as currently implemented, unless the quantity of each pair
is sufficiently high. This has to do with minimum liquidity requirements and
potential rounding issues

Router implementation soon

More advanced LPing and trading schema for smaller NFT collections
