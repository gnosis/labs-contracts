/*
 * Please refer to https://docs.envio.dev for a thorough guide on all Envio indexer features
 */
import {
  OmenAgentResultMapping,
  OmenAgentResultMapping_PredictionAdded,
  OmenThumbnailMapping,
  OmenThumbnailMapping_ImageUpdated,
} from "generated";

OmenAgentResultMapping.PredictionAdded.handler(async ({ event, context }) => {
  const entity: OmenAgentResultMapping_PredictionAdded = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    marketAddress: event.params.marketAddress,
    estimatedProbabilityBps: event.params.estimatedProbabilityBps,
    publisherAddress: event.params.publisherAddress,
    txHashes: event.params.txHashes,
    ipfsHash: event.params.ipfsHash,
  };

  context.OmenAgentResultMapping_PredictionAdded.set(entity);
});

OmenThumbnailMapping.ImageUpdated.handler(async ({ event, context }) => {
  const entity: OmenThumbnailMapping_ImageUpdated = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    marketAddress: event.params.marketAddress,
    image_hash: event.params.image_hash,
    changer: event.params.changer,
  };

  context.OmenThumbnailMapping_ImageUpdated.set(entity);
});
