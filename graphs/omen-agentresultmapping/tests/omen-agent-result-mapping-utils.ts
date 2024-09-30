import { newMockEvent } from "matchstick-as"
import { ethereum, Address, Bytes } from "@graphprotocol/graph-ts"
import { PredictionAdded } from "../generated/OmenAgentResultMapping/OmenAgentResultMapping"

export function createPredictionAddedEvent(
  marketAddress: Address,
  estimatedProbabilityBps: i32,
  publisherAddress: Address,
  txHashes: Array<Bytes>,
  ipfsHash: Bytes
): PredictionAdded {
  let predictionAddedEvent = changetype<PredictionAdded>(newMockEvent())

  predictionAddedEvent.parameters = new Array()

  predictionAddedEvent.parameters.push(
    new ethereum.EventParam(
      "marketAddress",
      ethereum.Value.fromAddress(marketAddress)
    )
  )
  predictionAddedEvent.parameters.push(
    new ethereum.EventParam(
      "estimatedProbabilityBps",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(estimatedProbabilityBps))
    )
  )
  predictionAddedEvent.parameters.push(
    new ethereum.EventParam(
      "publisherAddress",
      ethereum.Value.fromAddress(publisherAddress)
    )
  )
  predictionAddedEvent.parameters.push(
    new ethereum.EventParam(
      "txHashes",
      ethereum.Value.fromFixedBytesArray(txHashes)
    )
  )
  predictionAddedEvent.parameters.push(
    new ethereum.EventParam("ipfsHash", ethereum.Value.fromFixedBytes(ipfsHash))
  )

  return predictionAddedEvent
}
