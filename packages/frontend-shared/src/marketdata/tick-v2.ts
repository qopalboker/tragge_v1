/**
 * MD-001 market-data tick contract v2 (frontend mirror).
 * Canonical definitions live in packages/contracts/ts/v2.
 */

export type AssetGroup = "forex" | "crypto";
export type TickQuality = "good" | "degraded" | "suspect" | "unusable";

export interface FixedPrice {
  units: number;
  scale: number;
}

export interface TickEventV2 {
  schema_version: 2;
  event_id: string;
  symbol: string;
  asset_group: AssetGroup;
  bid: FixedPrice;
  ask: FixedPrice;
  last?: FixedPrice;
  provider: string;
  provider_timestamp_ms: number;
  received_at_ms: number;
  published_at_ms: number;
  sequence: number;
  source_epoch: number;
  quality: TickQuality;
  is_synthetic: boolean;
  normalization_version: number;
}
