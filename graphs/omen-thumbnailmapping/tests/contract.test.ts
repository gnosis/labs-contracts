import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { Address, Bytes } from "@graphprotocol/graph-ts"
import { handleImageUpdated } from "../src/contract"
import { createImageUpdatedEvent } from "./contract-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Test OmenThumbnailMapping", () => {
  beforeAll(() => {
    let marketAddress = Address.fromString("0x0000000000000000000000000000000000000001")
    let image_hash = Bytes.fromI32(1234567890)
    let changer = Address.fromString("0x0000000000000000000000000000000000000002")
    let newImageUpdatedEvent = createImageUpdatedEvent(
      marketAddress,
      image_hash,
      changer
    )
    handleImageUpdated(newImageUpdatedEvent)
  })

  afterAll(() => {
    clearStore()
  })

  test("OmenThumbnailMapping created and stored", () => {
    assert.entityCount("OmenThumbnailMapping", 1)

    assert.fieldEquals(
      "OmenThumbnailMapping",
      "0x0000000000000000000000000000000000000001",
      "marketAddress",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "OmenThumbnailMapping",
      "0x0000000000000000000000000000000000000001",
      "image_hash",
      "1234567890"
    )
    assert.fieldEquals(
      "OmenThumbnailMapping",
      "0x0000000000000000000000000000000000000001",
      "changer",
      "0x0000000000000000000000000000000000000002"
    )
  })
})
