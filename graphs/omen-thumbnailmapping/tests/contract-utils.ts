import { newMockEvent } from "matchstick-as"
import { ethereum, Address, Bytes } from "@graphprotocol/graph-ts"
import { ImageUpdated } from "../generated/Contract/Contract"

export function createImageUpdatedEvent(
  marketAddress: Address,
  image_hash: Bytes,
  changer: Address
): ImageUpdated {
  let imageUpdatedEvent = changetype<ImageUpdated>(newMockEvent())

  imageUpdatedEvent.parameters = new Array()

  imageUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "id",
      ethereum.Value.fromAddress(marketAddress) // id is the marketAddress
    )
  )
  imageUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "marketAddress",
      ethereum.Value.fromAddress(marketAddress)
    )
  )
  imageUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "image_hash",
      ethereum.Value.fromFixedBytes(image_hash)
    )
  )
  imageUpdatedEvent.parameters.push(
    new ethereum.EventParam("changer", ethereum.Value.fromAddress(changer))
  )

  return imageUpdatedEvent
}
