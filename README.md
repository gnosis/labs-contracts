# Gnosis Labs Contracts

Repository holding the contracts made by Gnosis Labs team.

## Implemented contracts

### Omen ThumbnailMapping

Contract used to store prediction market's address to IPFS hash of an image displayed on Omen 2.0

## Set up

The repository uses [Foundry](https://book.getfoundry.sh/).

### Installation

See installation instructions on https://book.getfoundry.sh/getting-started/installation.

### Build

```shell
forge build
```

### Test

```shell
forge test
```

### Format

```shell
forge fmt
```

### Gas Snapshots

```shell
forge snapshot
```

### Anvil

```shell
anvil
```

### Deploy

#### On Anvil

Start Anvil with

```shell
anvil
```

and run

```shell
forge create --rpc-url 127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 OmenThumbnailMapping
```

#### On TestNet

```shell
forge create --gas-limit 10000000 --rpc-url https://rpc.chiadochain.net  --private-key <your_private_key> OmenThumbnailMapping
```

#### On MainNet

```shell
ETHERSCAN_API_KEY=<your_api_key> forge create --verify --verifier-url https://api.gnosisscan.io/api --rpc-url https://gnosis-rpc.publicnode.com --private-key <your_private_key> OmenThumbnailMapping
```

### Cast

```shell
cast <subcommand>
```

### Help

```shell
forge --help
anvil --help
cast --help
```
