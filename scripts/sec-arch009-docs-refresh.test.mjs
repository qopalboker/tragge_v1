/**
 * ARCH-009 — architecture docs match staged topology (not live production).
 */
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (rel) => fs.readFileSync(path.join(root, rel), "utf8");

test("ARCH-009 staged topology and inventory docs exist", () => {
  for (const rel of [
    "docs/architecture/staged-runtime-topology.md",
    "docs/architecture/service-inventory.md",
    "docs/codex/reports/ARCH-009-docs-refresh.md",
    "docs/codex/decisions/ARCH-009-decision-log.md",
  ]) {
    assert.ok(fs.existsSync(path.join(root, rel)), rel);
  }
});

test("ARCH-009 audit declares NO-GO and local/no-user environment", () => {
  const audit = read("docs/architecture/current-state-audit.md");
  assert.match(audit, /ARCH-009/);
  assert.match(audit, /NO-GO/);
  assert.match(audit, /local \/ no-user|no-user/i);
  assert.match(audit, /not.*live-production|Not\*\* evidence of live-production/i);
  assert.match(audit, /apps\/platform/);
  assert.match(audit, /profile=target|profile=\*\*`target`|Compose profile \*\*`target`/);
  assert.match(audit, /SAFE_TO_DELETE/);
});

test("ARCH-009 topology documents target Platform + Engine + Market Data", () => {
  const topo = read("docs/architecture/staged-runtime-topology.md");
  assert.match(topo, /```mermaid/);
  assert.match(topo, /platform --mode=api/);
  assert.match(topo, /trading-engine/);
  assert.match(topo, /market-ingestor/);
  assert.match(topo, /DEPRECATED|legacy-wrappers|Transitional/);
  assert.match(topo, /MD001-KAFKA-V2-CUTOVER/);
  assert.match(topo, /ARCH007-WRAPPER-DELETE/);
  assert.match(topo, /INFRA-002/);
});

test("ARCH-009 inventory lists money package and platform", () => {
  const inv = read("docs/architecture/service-inventory.md");
  assert.match(inv, /platform/);
  assert.match(inv, /money/);
  assert.match(inv, /marketdata\/v2|tick_event\.v2|marketdata\/v2/);
  assert.match(inv, /111 ups|Legacy/);
});

test("ARCH-009 phase-3 notes target supersession", () => {
  const p3 = read("docs/architecture/phase-3-production-runtime.md");
  assert.match(p3, /superseded|ARCH-007\/009|ARCH-009/);
  assert.match(p3, /profile=target|platform --mode=api/);
});

test("ARCH-009 keeps FIN-006/MD-005A called out as separate", () => {
  const topo = read("docs/architecture/staged-runtime-topology.md");
  assert.match(topo, /FIN-006/);
  assert.match(topo, /MD-005A/);
});
