import { newMockEvent } from "matchstick-as"
import { ethereum, Address, Bytes } from "@graphprotocol/graph-ts"
import { PredictionAdded } from "../generated/Contract/Contract"

export function createPredictionAddedEvent(
  marketAddress: Address,
  estimatedProbabilityBps: i32,
  publisherAddress: Address,
  txHash: Bytes,
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
    new ethereum.EventParam("txHash", ethereum.Value.fromFixedBytes(txHash))
  )
  predictionAddedEvent.parameters.push(
    new ethereum.EventParam("ipfsHash", ethereum.Value.fromFixedBytes(ipfsHash))
  )

  return predictionAddedEvent
}
