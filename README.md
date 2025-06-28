# Gnosis Labs Contracts

Repository holding the contracts made by Gnosis Labs team.

## Implemented contracts

| Contract Name           | Description                                           | Mainnet Address                                                                                                           | TheGraph                                                                                     |
|-------------------------|-------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------|
| OmenThumbnailMapping    | Manages IPFS hashes for market thumbnails on Omen 2.0 | [0xe0cf08311F03850497B0ed6A2cf067f1750C3eFc](https://gnosisscan.io/address/0xe0cf08311f03850497b0ed6a2cf067f1750c3efc#code) | [omen-thumbnailmapping](https://thegraph.com/studio/subgraph/omen-thumbnailmapping/)         |
| OmenAgentResultMapping  | Maps prediction results to markets on Omen 2.0        | [0x99c43743A2dbd406160CC43cf08113b17178789c](https://gnosisscan.io/address/0x99c43743A2dbd406160CC43cf08113b17178789c#code) | TBA     |
| SeerAgentResultMapping  | Maps prediction results to markets on Seer        | [0x1aafdfBD38EE92A4a74A44A1614E00894205074e](https://gnosisscan.io/address/0x1aafdfBD38EE92A4a74A44A1614E00894205074e#code) | TBA     |
| Agent NFT               | Agent NFTs that control mechs for NFT game            | [0x0D7C0Bd4169D090038c6F41CFd066958fe7619D0](https://gnosisscan.io/address/0x0D7C0Bd4169D090038c6F41CFd066958fe7619D0#code) |  |
| Agent Registry contract               | Simple contract storing active agent addresses            | [0xe8ae78b19c997b6da8189b1a644d4076f8bc880e](https://gnosisscan.io/address/0xe8ae78b19c997b6da8189b1a644d4076f8bc880e#code) |  |
| Agent communication contract               | Simple contract storing message queue for each agent            | [0x219083Fc5315fdc145eE5C0eb22CbE12d6115c53](https://gnosisscan.io/address/0x219083Fc5315fdc145eE5C0eb22CbE12d6115c53#code) |  |
| Simple Treasury contract               | Contract for storing the NFT agent game treasury | [0x624ad0db52e6b18afb4d36b8e79d0c2a74f3fc8a](https://gnosisscan.io/address/0x624ad0db52e6b18afb4d36b8e79d0c2a74f3fc8a#code) |  |
| NoSingleSignedTransactionGuard     | Safe Guard that only allows transactions with at least 2 signers. | [0x43eff50Dc1Db7c084d2488792C7df28C0c3558D5](https://gnosisscan.io/address/0x43eff50Dc1Db7c084d2488792C7df28C0c3558D5#code)   | none |
| DebuggingContract     | Add whatever function you need here to test out | [0x5Aa82E068aE6a6a1C26c42E5a59520a74Cdb8998](https://gnosisscan.io/address/0x5Aa82E068aE6a6a1C26c42E5a59520a74Cdb8998#code)   | none |
| BetContractFactory     | Factory that creates BetContracts for existing FPMM markets | [0xf671142603addba312ed8fbfd39c0890c7a46e54](https://gnosis.blockscout.com/address/0xF671142603aDdBa312eD8fBFD39C0890C7A46e54?tab=contract_code)   | none |


## Set up contracts development

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

#### (Optional) Deploy on a Tenderly testnet
forge create AgentResultMapping \
--constructor-args "Omen" \
--private-key <private_key> \ 
--rpc-url <tenderly_rpc_url>  \
--etherscan-api-key <tenderly-access-token> \
--verify \
--verifier-url <tenderly_roc_url>/verify/etherscan


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

## Set up graph development

Graphs uses [The Graph](https://thegraph.com/docs).

### Installation

See installation instructions on https://thegraph.com/docs/en/developing/creating-a-subgraph/#install-the-graph-cli.

Then open directory of one of the graphs and run `npm install`.

### Build, test, deploy

Before working with graphs, you need to run `forge build` in the root directory.

- `omen-thumbnailmapping` - see `graphs/omen-thumbnailmapping/package.json`

The sequence of commands is `codegen -> build -> test -> deploy`.

(On MacOS Sonoma, running the tests in the docker mode is required: https://github.com/LimeChain/matchstick/issues/421)

## Set Envio deployment

We deploy the subgraph on `graphs/envio-subgraphs` to Envio.
One can run 

### Start subgraph locally

Make sure Docker is running locally

```shell
pnpm run dev
```

and to stop
```
pnpm envio stop
```

### Deploy subgraph

The subgraph is already connected to Envio. If changes need to be made, simply commit and push to the envio branch (use Envio API Key).
Note that every time a new deployment is done, the indexer URL changes, thus changing this in [PMAT](https://github.com/gnosis/prediction-market-agent-tooling) is necessary.