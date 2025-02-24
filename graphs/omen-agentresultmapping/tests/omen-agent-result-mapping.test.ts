import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { Address, Bytes } from "@graphprotocol/graph-ts"
import { PredictionAdded } from "../generated/schema"
import { PredictionAdded as PredictionAddedEvent } from "../generated/OmenAgentResultMapping/OmenAgentResultMapping"
import { handlePredictionAdded } from "../src/omen-agent-result-mapping"
import { createPredictionAddedEvent } from "./omen-agent-result-mapping-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let marketAddress = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    )
    let estimatedProbabilityBps = 123
    let publisherAddress = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    )
    let txHashes = [Bytes.fromI32(1234567890)]
    let ipfsHash = Bytes.fromI32(1234567890)
    let newPredictionAddedEvent = createPredictionAddedEvent(
      marketAddress,
      estimatedProbabilityBps,
      publisherAddress,
      txHashes,
      ipfsHash
    )
    handlePredictionAdded(newPredictionAddedEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("PredictionAdded created and stored", () => {
    assert.entityCount("PredictionAdded", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "PredictionAdded",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "marketAddress",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "PredictionAdded",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "estimatedProbabilityBps",
      "123"
    )
    assert.fieldEquals(
      "PredictionAdded",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "publisherAddress",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "PredictionAdded",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "txHashes",
      "[1234567890]"
    )
    assert.fieldEquals(
      "PredictionAdded",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "ipfsHash",
      "1234567890"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
