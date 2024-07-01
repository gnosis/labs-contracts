import {
  Entity,
  Value,
  ValueKind,
  store,
  Bytes,
} from "@graphprotocol/graph-ts";

export class OmenThumbnailMapping extends Entity {
  constructor(marketAddress: Bytes) {
    super();
    this.set("marketAddress", Value.fromBytes(marketAddress));
  }

  save(): void {
    let marketAddress = this.get("marketAddress");
    let image_hash = this.get("image_hash");
    assert(marketAddress != null, "Cannot save OmenThumbnailMapping entity without an marketAddress");
    assert(image_hash != null, "Cannot save OmenThumbnailMapping entity without an image_hash");
    if (marketAddress && image_hash) {
      assert(
        marketAddress.kind == ValueKind.BYTES,
        `Entities of type OmenThumbnailMapping must have an marketAddress of type Bytes but the marketAddress '${marketAddress.displayData()}' is of type ${marketAddress.displayKind()}`,
      );
      assert(
        image_hash.kind == ValueKind.BYTES,
        `Entities of type OmenThumbnailMapping must have an image_hash of type Bytes but the image_hash '${image_hash.displayData()}' is of type ${image_hash.displayKind()}`,
      );
      store.set("OmenThumbnailMapping", marketAddress.toBytes().toHexString(), this);
    }
  }

  static loadInBlock(marketAddress: Bytes): OmenThumbnailMapping | null {
    return changetype<OmenThumbnailMapping | null>(
      store.get_in_block("OmenThumbnailMapping", marketAddress.toHexString()),
    );
  }

  static load(marketAddress: Bytes): OmenThumbnailMapping | null {
    return changetype<OmenThumbnailMapping | null>(
      store.get("OmenThumbnailMapping", marketAddress.toHexString()),
    );
  }

  get id(): Bytes {
    return this.marketAddress;
  }

  set id(value: Bytes) {
    this.marketAddress = value;
  }

  get marketAddress(): Bytes {
    let value = this.get("marketAddress");
    if (!value || value.kind == ValueKind.NULL) {
      throw new Error("Cannot return null for a required field.");
    } else {
      return value.toBytes();
    }
  }

  set marketAddress(value: Bytes) {
    this.set("marketAddress", Value.fromBytes(value));
    // We need to set ID like this (even though it's accessed via marketAddress anyway), because the ID is required by the Entity class 
    // and it checks for it. However in our case, the ID and marketAddress is the same thing.
    this.set("id", Value.fromBytes(value));
  }

  get image_hash(): Bytes {
    let value = this.get("image_hash");
    if (!value || value.kind == ValueKind.NULL) {
      throw new Error("Cannot return null for a required field.");
    } else {
      return value.toBytes();
    }
  }

  set image_hash(value: Bytes) {
    this.set("image_hash", Value.fromBytes(value));
  }
}
