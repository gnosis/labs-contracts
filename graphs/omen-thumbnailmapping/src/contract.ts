import { ImageUpdated } from "../generated/Contract/Contract"
import { OmenThumbnailMapping } from "./schema"

export function handleImageUpdated(event: ImageUpdated): void {
  let mapping = OmenThumbnailMapping.load(event.params.marketAddress)

  if (!mapping) {
    mapping = new OmenThumbnailMapping(event.params.marketAddress)
  }

  mapping.marketAddress = event.params.marketAddress
  mapping.image_hash = event.params.image_hash

  mapping.save()
}
