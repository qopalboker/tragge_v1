/**
 * MD-001: re-export canonical tick contract v2 for User frontend.
 * Live websocket/chart consumers still use legacy float ticks until MD001-FRONTEND-CUTOVER.
 */
export type {
  AssetGroup,
  TickQuality,
  FixedPrice,
  TickEvent,
  FeedControlEvent,
} from "@tragge/contracts/v2";
export { assertTickEvent } from "@tragge/contracts/v2";
