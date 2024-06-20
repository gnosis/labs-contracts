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

```shell
forge create --rpc-url <your_rpc_url>  --private-key <your_private_key> src/OmenThumbnailMapping.sol:OmenThumbnailMapping
```

- Gnosis Network ID: 100
- Gnosis Chiado RPC: https://rpc.chiadochain.net
- Gnosis Chain RPC: https://gnosis-rpc.publicnode.com

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
