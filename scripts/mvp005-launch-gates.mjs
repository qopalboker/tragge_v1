#!/usr/bin/env node
/**
 * MVP-005 launch gate structural checks.
 * Verifies production-critical defaults in source and deployment config.
 * Does not print secrets.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const failures = [];

function read(rel) {
	const p = path.join(root, rel);
	if (!fs.existsSync(p)) {
		failures.push(`missing file: ${rel}`);
		return '';
	}
	return fs.readFileSync(p, 'utf8');
}

function mustInclude(rel, re, label) {
	const src = read(rel);
	if (!src) return;
	if (!re.test(src)) failures.push(`${rel}: missing ${label} (${re})`);
}

function mustNotInclude(rel, re, label) {
	const src = read(rel);
	if (!src) return;
	if (re.test(src)) failures.push(`${rel}: forbidden ${label} (${re})`);
}

// Deposit minimum $4 (400 cents)
mustInclude(
	'apps/payment-service/server/config.go',
	/MIN_DEPOSIT_CENTS[^\n]*400/,
	'default MIN_DEPOSIT_CENTS=400',
);
mustInclude(
	'infra/docker/docker-compose.yml',
	/MIN_DEPOSIT_CENTS:.*400/,
	'compose MIN_DEPOSIT_CENTS=400',
);

// Platform fee 20% (2000 bps)
mustInclude(
	'apps/settlement-service/server/config.go',
	/PLATFORM_FEE_BPS[^\n]*2000/,
	'default PLATFORM_FEE_BPS=2000',
);
mustInclude(
	'infra/docker/docker-compose.yml',
	/PLATFORM_FEE_BPS:\s*"2000"/,
	'compose PLATFORM_FEE_BPS=2000',
);
mustNotInclude(
	'infra/docker/docker-compose.yml',
	/PLATFORM_FEE_BPS:\s*"1700"/,
	'legacy 17% platform fee',
);

// QTY policy
mustInclude(
	'packages/contracts/v1/enums.go',
	/ContestDurationRush30Min:\s*\n\s*return 5/,
	'30m qty 5',
);
mustInclude(
	'packages/contracts/v1/enums.go',
	/case ContestDurationHourly:\s*\n\s*return 10/,
	'1h qty 10',
);
mustInclude(
	'packages/contracts/v1/enums.go',
	/case ContestDurationFourHour:\s*\n\s*return 10/,
	'4h qty 10',
);
mustInclude(
	'packages/contracts/v1/enums.go',
	/case ContestDurationDaily:\s*\n\s*return 20/,
	'1d qty 20',
);
mustInclude(
	'packages/contracts/v1/enums.go',
	/case ContestDurationWeekly:\s*\n\s*return 20/,
	'1w qty 20',
);

// Manual withdrawals
mustInclude(
	'apps/payment-service/handlers/withdraw.go',
	/manualPayoutProvider\s*=\s*"manual"/,
	'manual withdrawal provider',
);
mustInclude(
	'apps/admin-bff/server/handlers_withdrawal.go',
	/transaction_id/,
	'admin paid requires transaction_id path',
);

// Auth isolation still present
mustInclude(
	'apps/api-server/auth_contexts.go',
	/buildAuthContexts|ContextUser|ContextAdmin/,
	'auth isolation wiring',
);

// Migrations for critical MVP features
for (const m of [
	'packages/db/migrations/0101_telegram_auth.up.sql',
	'packages/db/migrations/0102_payout_manual_fields.up.sql',
	'packages/db/migrations/0090_provider_payment_id_unique.up.sql',
	'packages/db/migrations/0025_withdrawal_management.up.sql',
]) {
	if (!fs.existsSync(path.join(root, m))) failures.push(`missing migration: ${m}`);
}

// No hard-coded production secrets (coarse scan of source trees).
// Exclude tests and this checker (they intentionally mention patterns).
const secretSmell = /sk_live_[A-Za-z0-9]{10,}|pk_live_[A-Za-z0-9]{10,}|PLISIO_SECRET_KEY\s*=\s*["'][a-zA-Z0-9_-]{20,}["']/;
for (const dir of ['apps', 'packages', 'scripts']) {
	const walk = (d) => {
		for (const ent of fs.readdirSync(d, { withFileTypes: true })) {
			if (ent.name === 'node_modules' || ent.name === 'dist' || ent.name === '.git') continue;
			const full = path.join(d, ent.name);
			if (ent.isDirectory()) walk(full);
			else if (/\.(go|ts|vue|js|mjs|yml|yaml|env\.example)$/.test(ent.name)) {
				if (/\.(test|spec)\./.test(ent.name) || ent.name.endsWith('_test.go')) continue;
				if (ent.name === 'mvp005-launch-gates.mjs') continue;
				const txt = fs.readFileSync(full, 'utf8');
				if (secretSmell.test(txt)) {
					failures.push(`possible hard-coded secret: ${path.relative(root, full)}`);
				}
			}
		}
	};
	walk(path.join(root, dir));
}

if (failures.length) {
	console.error('MVP-005 launch gates FAILED:');
	for (const f of failures) console.error(' -', f);
	process.exit(1);
}
console.log('MVP-005 launch gates PASS');
process.exit(0);
