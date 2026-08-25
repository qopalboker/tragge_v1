# ARCH-003 decision log

**Date:** 2026-08-25

## Generation ownership

Platform `scheduler` module is the sole contest-generation owner. Standalone `free-contest-generator` is disabled by default; emergency override via `PLATFORM_ALLOW_STANDALONE_FREE_GENERATOR=true`.

## Leaderboard authority

Leaderboard is projection-only. It must not mark `wallets_credited` or expose settlement APIs.
