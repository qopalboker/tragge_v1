// Package money provides DATA-001 canonical fixed-point financial primitives.
//
// Defaults (policy-approved 2026-08-25):
//   - Money is signed int64 minor units (USDT display scale 2; type carries no float).
//   - Basis points are signed int (platform_fee_bps = 2000).
//   - Price / Rate / PnL / Score are signed int64 units + explicit scale
//     (default price/rate/PnL scale 8; default score scale 6).
//   - Rounding mode is half_away_from_zero (half_up for positives).
//   - Overflow and invalid precision fail closed.
//
// Symbol-specific price scales may later override defaults via MD-001/ENG-002 registry metadata.
package money
