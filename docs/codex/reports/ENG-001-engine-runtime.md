# ENG-001 — Separate Trading Engine runtime and Platform contracts

**Branch:** `codex/eng-001-separate-trading-engine-runtime-and-define`  
**Commit:** `refactor(engine): establish independent runtime boundary`

## What changed

| Area | Change |
|---|---|
| Entrypoint | `apps/trading-engine/cmd/trading-engine` |
| Image | `apps/trading-engine/Dockerfile` (`POSTGRES_USER=engine`) |
| Compose | `infra/docker/docker-compose.engine-standalone.yml` profile |
| Startup | `ValidateIndependentRuntime` rejects provider + JWT secrets; refuses Platform DB user |
| Contracts | `packages/contracts/engine/v1` commands/events + golden fixture |
| CI | `scripts/sec-eng001-engine-runtime.test.mjs` |

## Tests run this session

```text
go test ./engine/...                                      # packages/contracts
go test ./server -run 'TestValidateIndependentRuntime|TestUsesPlatformDBGrants|TestEngineSchemaOwnerBoundary'
node --test scripts/sec-eng001-engine-runtime.test.mjs
```

## Gaps (not runtime-verified)

- Docker image build/start against live Compose (`ENG001-COMPOSE-RESTART-E2E`)
- Full retirement of `trading-core` embedding Engine (`ENG001-TRADING-CORE-CUTOVER`)
- End-to-end Kafka publish/consume of engine/v1 contracts
- Prior open gaps remain open
