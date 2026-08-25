# CI-004 decision log

## 2026-08-25 — Continuous secret scanning

**Choice:** Run `gitleaks/gitleaks-action@v2` on every PR/push via always-on CI job `ci-004-secret-scanning`, plus a Node test that verifies workflow wiring (and local fixture catch when `gitleaks` is installed).

**Not claimed:** Historical full-repo secret audit beyond scanner rules; GitHub Advanced Security secret scanning UI.
