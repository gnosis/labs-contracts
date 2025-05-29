import assert from "assert";
import { 
  TestHelpers,
  OmenAgentResultMapping_PredictionAdded
} from "generated";
const { MockDb, OmenAgentResultMapping } = TestHelpers;

describe("OmenAgentResultMapping contract PredictionAdded event tests", () => {
  // Create mock db
  const mockDb = MockDb.createMockDb();

  // Creating mock for OmenAgentResultMapping contract PredictionAdded event
  const event = OmenAgentResultMapping.PredictionAdded.createMockEvent({/* It mocks event fields with default values. You can overwrite them if you need */});

  it("OmenAgentResultMapping_PredictionAdded is created correctly", async () => {
    // Processing the event
    const mockDbUpdated = await OmenAgentResultMapping.PredictionAdded.processEvent({
      event,
      mockDb,
    });

    // Getting the actual entity from the mock database
    let actualOmenAgentResultMappingPredictionAdded = mockDbUpdated.entities.OmenAgentResultMapping_PredictionAdded.get(
      `${event.chainId}_${event.block.number}_${event.logIndex}`
    );

    // Creating the expected entity
    const expectedOmenAgentResultMappingPredictionAdded: OmenAgentResultMapping_PredictionAdded = {
      id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
      marketAddress: event.params.marketAddress,
      estimatedProbabilityBps: event.params.estimatedProbabilityBps,
      publisherAddress: event.params.publisherAddress,
      txHashes: event.params.txHashes,
      ipfsHash: event.params.ipfsHash,
    };
    // Asserting that the entity in the mock database is the same as the expected entity
    assert.deepEqual(actualOmenAgentResultMappingPredictionAdded, expectedOmenAgentResultMappingPredictionAdded, "Actual OmenAgentResultMappingPredictionAdded should be the same as the expectedOmenAgentResultMappingPredictionAdded");
  });
});
