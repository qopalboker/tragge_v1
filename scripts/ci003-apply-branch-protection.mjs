/**
 * CI-003: apply main branch protection with required status checks.
 *
 * Env:
 *   GITHUB_TOKEN or GH_TOKEN — repo admin token
 *   GITHUB_REPOSITORY — owner/repo (default qopalboker/tragge_v1)
 */
const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;
if (!token) {
  console.error("GITHUB_TOKEN/GH_TOKEN required");
  process.exit(2);
}
const repo = process.env.GITHUB_REPOSITORY || "qopalboker/tragge_v1";
const api = `https://api.github.com/repos/${repo}/branches/main/protection`;

const REQUIRED_CONTEXTS = [
  "CI required gate",
  "Go CI complete",
  "Frontend CI complete",
  "CI-002 critical Go coverage floor",
  "SEC-008 auth regression lock",
  "SEC-009 admin reauth + Super Admin MFA",
];

const body = {
  required_status_checks: {
    strict: true,
    contexts: REQUIRED_CONTEXTS,
  },
  enforce_admins: false,
  required_pull_request_reviews: {
    dismiss_stale_reviews: true,
    require_code_owner_reviews: false,
    // Process expects review; count 0 keeps automation unblocked.
    // Enabling count=1 tracked as CI003-REVIEW-ENFORCEMENT.
    required_approving_review_count: 0,
  },
  restrictions: null,
  allow_force_pushes: false,
  allow_deletions: false,
  required_linear_history: false,
  allow_squash_merge: undefined,
};

const res = await fetch(api, {
  method: "PUT",
  headers: {
    Authorization: `Bearer ${token}`,
    Accept: "application/vnd.github+json",
    "X-GitHub-Api-Version": "2022-11-28",
    "Content-Type": "application/json",
  },
  body: JSON.stringify(body),
});
const text = await res.text();
if (!res.ok) {
  console.error(res.status, text);
  process.exit(1);
}
console.log("Applied main branch protection with contexts:", REQUIRED_CONTEXTS.join(", "));
console.log(text.slice(0, 500));
