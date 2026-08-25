# Platform modular monolith (ARCH-001 skeleton)

One codebase, one image, three runtime modes per ADR-0001 / policy §2.2:

```bash
platform --mode=api
platform --mode=realtime
platform --mode=worker
```

## Layout

- `cmd/platform` — entrypoint
- `internal/compose` — composition root (wires modules; only place that constructs repositories)
- `internal/modules/*` — identity, contest, wallet, payment, kyc, settlement, leaderboard, notification, ticket, admin, scheduler (stubs)
- `internal/adapters/{api,realtime,worker}` — mode shells with independent `/healthz` and `/readyz`

## Boundary rule

Adapters and handlers depend on module **Service** interfaces only. Module **repository** types are unexported. Import-boundary tests enforce adapters do not import `internal/modules/<name>` packages directly.

## Image

```bash
docker build -f apps/platform/Dockerfile -t tragge/platform:dev .
docker run --rm -p 8080:8080 tragge/platform:dev --mode=api
```

Compose sketch: `infra/docker/docker-compose.platform.yml`.

## Out of scope (later ARCH-*)

Migrating real BFF/worker logic into these modules (ARCH-002+).
