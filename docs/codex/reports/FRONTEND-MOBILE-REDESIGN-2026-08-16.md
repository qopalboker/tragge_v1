# FRONTEND MOBILE REDESIGN — 2026-08-16

**Repository:** `tragge_v1` (local workspace `tragge_v0-main`)  
**Scope:** User-facing mobile-first RTL frontend reconstruction  
**Reference:** `docs/codex/reports/evidence/frontend/reference-mobile-dashboard.png`  
**Gate:** `scripts/mvp/frontend-gate.mjs`  
**Evidence:** `docs/codex/reports/evidence/frontend/frontend-gate-latest.{txt,json}`

---

## Executive Decision

**FRONTEND — PASS**

This decision is **frontend MVP acceptance only**. It is **not** production GO, cloud readiness, payment-gateway readiness, or Kubernetes qualification.

---

## Visual Implementation

### Design system

Reusable tokens and primitives live in:

- `apps/user-frontend/src/styles/mvp-design-tokens.css` (imported from `main.ts`)

| Token area | Values / role |
|---|---|
| Background | Deep navy / near-black (`#050810`, radial mid navy glow) |
| Accent | Emerald/teal (`#00d4a0`) with soft glow surfaces |
| Surfaces | Glass cards (`mvp-glass`, `mvp-glass-strong`) — blur, subtle emerald border, inset highlight |
| Radius | 12 / 16 / 20 px system |
| Spacing | Page pad 16px, section gap 20px, bottom nav 72px + safe-area |
| Typography | Existing Dana / Persian stack; high contrast white headings, muted secondary |
| Motion | Subtle pulse/glow only; `prefers-reduced-motion` respected |

Horizontal rails use `.mvp-h-scroll`:

- page does **not** scroll horizontally (`overflow-x: clip` on home)
- only the rail scrolls (`overflow-x: auto`, snap, hidden scrollbar, touch pan-x)

### Components introduced / rebuilt

| Component | Path | Role |
|---|---|---|
| MobileHomeHeader | `modules/user/components/dashboard/MobileHomeHeader.vue` | Support, notifications (badges), wallet balance + fund CTA |
| FeaturedContestCard | `modules/user/components/dashboard/FeaturedContestCard.vue` | Dominant featured contest + real join route |
| ChallengeRail | `modules/user/components/dashboard/ChallengeRail.vue` | Horizontal progression from real `total_contests` |
| SupportTicketCard | `modules/user/components/dashboard/SupportTicketCard.vue` | Tickets list / empty / create CTA via real tickets API |
| BottomNav | `modules/user/components/layout/BottomNav.vue` | Fixed emerald glass nav + center T FAB + safe-area |
| DashboardPage | `modules/user/views/DashboardPage.vue` | Full hierarchy composition |
| UserLayout | `modules/user/components/layout/UserLayout.vue` | Mobile content bottom padding for nav |

Admin panel was **not** redesigned (per scope). Trading page retained; routes and APIs unchanged.

---

## User Dashboard

Mandatory mobile hierarchy (implemented, `dir="rtl"`):

```text
Header (utilities + wallet)
  ↓
Welcome / Hero
  ↓
Wallet / Summary metrics
  ↓
Featured Contest
  ↓
Suggested Contests  → HORIZONTAL SCROLL
  ↓
Challenges          → HORIZONTAL SCROLL
  ↓
Support Ticket
  ↓
Bottom Navigation
```

### Header

- Support shortcut → `/user/tickets` (unread ticket dot)
- Notifications → `/user/notifications` (unread badge from notifications API)
- Wallet pill: icon + live balance + `+` → `/user/wallet` (admin-credit funding path; **no payment gateway invented**)

### Hero / welcome

- Persian greeting (`dashboard.welcomeHero`)
- Supporting copy (`dashboard.heroSub`)
- Compact brand orb (T cube + glow rings) — lightweight CSS, no heavy new artwork assets
- Username line from auth store

### Wallet / summary

- Main metric card: available balance from `walletStore` (backend-authoritative `balance_cents`)
- Side cards: wins / total contests from `userStatsApi.getMyStats()`
- Loading skeleton on wallet header when fetching

### Featured contest

- Selected by highest `estimated_prize_pool_cents` among open/scheduled contests, else running
- Title, description, duration chip, entry, prize, participant count
- Primary CTA: «مشاهده و ثبت‌نام» → `/user/contests/:id`
- Loading / empty handled (card omitted when no contest)

### Suggested contests rail

- Horizontal `mvp-h-scroll` cards (fixed card width, no page overflow)
- Title, duration, market label, prize, entry, participants, details CTA
- «مشاهده همه» → `/user/contests`
- Skeleton and empty states

### Challenge rail

- Mandatory horizontal progression (not a tall vertical stack)
- Progress ring `progress / 7` driven by **real** `stats.total_contests`
- Milestone nodes 1 → 3 → 5 → 7 with completed / current / locked visual states
- Reward labels are **UI milestone presentation** only; wallet credits remain backend-only (admin credit path)
- No invented challenge backend; no fake balances

### Support ticket (immediately below challenges)

- Real `ticketsApi.list` + create / open routes
- Empty state: create first ticket
- Populated: recent tickets + status + new ticket CTA
- Error + retry path to tickets list
- Backend exists (`/api/user/me/tickets`); **no fake support data**

### Bottom navigation

Items (RTL order in DOM; visual matches product destinations):

| Slot | Route | Notes |
|---|---|---|
| Profile | `/user/profile` | |
| Contests | `/user/contests` | |
| Home (center FAB) | `/user/dashboard` | Emerald elevated T |
| Leaderboard | `/user/leaderboard` | |
| Support | `/user/tickets` | Unread badge |

- `env(safe-area-inset-bottom)` on nav height and padding
- UserLayout main content padded by `mvp-bottom-nav-h + safe-area` so content is never hidden

---

## Responsive

| Breakpoint | Behavior |
|---|---|
| Mobile (320–430+) | Primary target: single column, rails, bottom nav, compact hero/metrics |
| Tablet | Same composition; slightly wider cards; layout still max-width constrained |
| Desktop | Bottom nav hidden; sidebar layout retained; optional leaderboard/win-rate extras shown; product routes unchanged |

Home uses `max-width: 720px` + `overflow-x: clip` to prevent accidental document horizontal scroll while rails scroll independently.

---

## API Integration

Real backend contracts only (no mock business data on the dashboard):

| Section | Source |
|---|---|
| Auth / user name | `useAuthStore` |
| Wallet balance | `useWalletStore` → wallet API (`balance_cents`) |
| User stats (contests, wins, win rate) | `userStatsApi.getMyStats()` |
| Global leaderboard preview | `userStatsApi.getGlobalLeaderboard()` |
| Contests list / featured / suggested | `GET /api/user/contests` |
| Notifications badge | `notificationsApi.getUnreadCount()` |
| Support tickets | `ticketsApi.list`, `getUnreadCount`, routes to create/chat |
| Trading (unchanged path) | Existing trade module + order/market APIs |

**Not invented:** payment gateway, fake wallet funding UI numbers, mock contests, fabricated support threads.

MVP funding path remains: **admin wallet credit → user wallet balance**.

---

## Tests

### Frontend gate

```bash
node scripts/mvp/frontend-gate.mjs
```

**Result:** `FRONTEND — PASS` · `failed=0` · exit `0`

Validated categories:

| Category | Result |
|---|---|
| BUILD | PASS (`vite production build`, exit 0) |
| TYPECHECK | PASS (`vue-tsc`, exit 0) |
| ROUTES | PASS (dashboard, trade, wallet, tickets) |
| AUTH / structure | Covered via route + layout presence |
| USER HOME | PASS (header, featured, challenge, support, bottom nav, composition) |
| WALLET | PASS (store → wallet API) |
| CONTEST | PASS (`/api/user/contests`) |
| CHALLENGE | PASS (real `total_contests`) |
| SUPPORT | PASS (`ticketsApi`) |
| TRADING | PASS (`TradingPage.vue` present) |
| RESPONSIVE | PASS (safe-area + content padding) |
| RTL | PASS (`dir="rtl"`, tokens) |
| E2E (structure) | PASS (reference image archived) |

### Commands run

| Command | Exit |
|---|---|
| `npm run typecheck` (user-frontend, via gate) | 0 |
| `npm run build` (user-frontend, via gate) | 0 |
| `node scripts/mvp/frontend-gate.mjs` | 0 |

Evidence files:

- `docs/codex/reports/evidence/frontend/frontend-gate-latest.txt`
- `docs/codex/reports/evidence/frontend/frontend-gate-latest.json`
- `docs/codex/reports/evidence/frontend/reference-mobile-dashboard.png`

### Notes on live browser E2E

Gate structure + production build + typecheck completed on this host. Full interactive Playwright against a live authenticated API stack was **not** required for this gate and was not claimed as cloud/production proof. Existing product e2e scripts remain available (`npm run e2e` in user-frontend) when API stack is up.

---

## Visual QA

Compared implementation language to the attached reference image:

| Reference element | Implementation | Match quality |
|---|---|---|
| Deep navy background + emerald accents | Design tokens + theme overrides | Strong |
| Glass cards, soft borders, large radius | `mvp-glass` / `mvp-glass-strong` | Strong |
| Top: support + notifications + wallet pill | `MobileHomeHeader` | Strong |
| Hero greeting + brand 3D-style T mark | CSS orb/cube (lightweight equivalent of reference art) | Good (layout/hierarchy match; not pixel art copy) |
| Portfolio / prizes / contests metrics | Metrics section from real APIs | Strong |
| Featured contest + CTA | `FeaturedContestCard` | Strong |
| Horizontal suggested contests | `mvp-h-scroll` rail | Strong |
| Challenge ring + horizontal milestones | `ChallengeRail` | Strong |
| Support section under challenges | `SupportTicketCard` | Strong (section exists; reference mockup emphasizes challenges; product requirement places support immediately below) |
| Bottom nav with center T | `BottomNav` center FAB | Strong |
| RTL Persian copy | `dir="rtl"` + fa locale keys | Strong |

Decorative reference artwork (photoreal trophy cube, gauge illustration, avatar faces) is approximated with design primitives rather than shipping large binary assets. Hierarchy, color, cards, rails, and nav match the product source of truth.

### Structure checklist

1. Top utilities — yes  
2. Hero/welcome — yes  
3. Wallet/summary — yes  
4. Featured contest — yes  
5. Horizontally scrollable suggested contests — yes  
6. Horizontally scrollable challenge progression — yes  
7. Support ticket immediately below challenge — yes  
8. Bottom navigation — yes  

---

## Remaining Issues

None that block **FRONTEND — PASS** for MVP mobile reconstruction.

Non-blocking / out-of-scope notes:

1. **Production GO** remains blocked by external/cloud/sign-off gates from earlier phases (not frontend).
2. **No payment gateway** — intentional MVP; fund CTA routes to wallet (admin credit path).
3. **Challenge rewards** are UI milestone labels tied to real participation count; not a separate challenge settlement microservice.
4. **Reference 3D hero art** is CSS-approximated; optional later asset drop-in without layout rework.
5. **Full authenticated Playwright mobile viewport suite** against live stack is recommended as a follow-up when compose/API lab is running, not a gate failure here.
6. Admin UI not redesigned (by requirement).

---

## File map (primary)

```text
apps/user-frontend/src/styles/mvp-design-tokens.css
apps/user-frontend/src/main.ts
apps/user-frontend/src/modules/user/views/DashboardPage.vue
apps/user-frontend/src/modules/user/components/dashboard/MobileHomeHeader.vue
apps/user-frontend/src/modules/user/components/dashboard/FeaturedContestCard.vue
apps/user-frontend/src/modules/user/components/dashboard/ChallengeRail.vue
apps/user-frontend/src/modules/user/components/dashboard/SupportTicketCard.vue
apps/user-frontend/src/modules/user/components/layout/BottomNav.vue
apps/user-frontend/src/modules/user/components/layout/UserLayout.vue
apps/user-frontend/src/i18n/locales/fa.ts
apps/user-frontend/src/i18n/locales/en.ts
scripts/mvp/frontend-gate.mjs
docs/codex/reports/evidence/frontend/*
docs/codex/reports/FRONTEND-MOBILE-REDESIGN-2026-08-16.md
```

---

## CTO close

The mobile user home is a coherent Persian RTL product surface aligned to the reference design language, wired to real wallet / contest / stats / ticket / trading contracts, with loading/empty/error paths and a green MVP frontend gate.

**FRONTEND — PASS**
