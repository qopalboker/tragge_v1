/**
 * MD-001 canonical fixed-point market tick (policy §9.7).
 * No binary floating-point prices on the wire.
 */

export type AssetGroup = "forex" | "crypto";
export type TickQuality = "good" | "degraded" | "suspect" | "unusable";

export interface FixedPrice {
  units: number; // int64 on wire; JS number safe for typical FX/crypto scales
  scale: number;
}

export interface TickEvent {
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

export type FeedControlType =
  | "gap"
  | "stale"
  | "pause"
  | "resume"
  | "source_switch";

export interface FeedControlEvent {
  schema_version: 2;
  event_id: string;
  type: FeedControlType;
  symbol?: string;
  asset_group?: AssetGroup;
  provider?: string;
  from_provider?: string;
  to_provider?: string;
  source_epoch: number;
  prev_sequence?: number;
  next_sequence?: number;
  missing_count?: number;
  reason: string;
  occurred_at_ms: number;
}

export function assertTickEvent(value: unknown): asserts value is TickEvent {
  const v = value as TickEvent;
  if (!v || typeof v !== "object") throw new Error("tick_event: not an object");
  if (v.schema_version !== 2) throw new Error("tick_event: schema_version must be 2");
  if (!v.event_id || !v.symbol || !v.provider) {
    throw new Error("tick_event: event_id, symbol, provider required");
  }
  if (!v.bid || typeof v.bid.units !== "number" || typeof v.bid.scale !== "number") {
    throw new Error("tick_event: bid fixed-point required");
  }
  if (!v.ask || typeof v.ask.units !== "number" || typeof v.ask.scale !== "number") {
    throw new Error("tick_event: ask fixed-point required");
  }
}
