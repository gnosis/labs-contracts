import { PredictionAdded as PredictionAddedEvent } from "../generated/OmenAgentResultMapping/OmenAgentResultMapping"
import { PredictionAdded } from "../generated/schema"

export function handlePredictionAdded(event: PredictionAddedEvent): void {
  let entity = new PredictionAdded(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.marketAddress = event.params.marketAddress
  entity.estimatedProbabilityBps = event.params.estimatedProbabilityBps
  entity.publisherAddress = event.params.publisherAddress
  entity.txHash = event.params.txHash
  entity.ipfsHash = event.params.ipfsHash

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
