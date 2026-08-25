import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
test('DOC-002 PR template requires docs sync checklist', () => {
  const t = fs.readFileSync(path.join(root, '.github/pull_request_template.md'), 'utf8');
  assert.match(t, /DOC-002/);
  assert.match(t, /Documentation sync/);
  assert.match(t, /doc-noop rationale/);
  assert.match(t, /discovered-issues\.md/);
});
test('DOC-002 CLAUDE and audit remain NO-GO', () => {
  const c = fs.readFileSync(path.join(root, 'CLAUDE.md'), 'utf8');
  const a = fs.readFileSync(path.join(root, 'docs/architecture/current-state-audit.md'), 'utf8');
  assert.match(c, /NO-GO/);
  assert.match(a, /NO-GO/);
  assert.match(a, /DOC-002/);
});
