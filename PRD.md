# Product Requirements Document (PRD)

## Household Chores — iOS Native App

| Field | Value |
|--------|--------|
| **Document type** | Product requirements (functional + non-functional) |
| **Platform** | iOS (native), initial scope iPhone; iPad adaptive layout as stretch |
| **Status** | Draft for review |
| **Out of scope for this document** | Implementation, visual design system, engineering estimates |

---

## 1. Executive summary

This product is a **household chore manager** for multiple people sharing one home. It emphasizes **fair effort distribution** (via configurable **effort points** per job), **reliable reminders** (including **recurring notifications**), and **flexible execution** through **mood-based task reshuffling** so work still progresses when energy, time, or preferences change.

Success is measured by sustained household use, perceived fairness, fewer missed chores, and reduced negotiation overhead.

---

## 2. Problem statement

Shared households struggle with:

- **Opaque fairness:** counting “tasks completed” ignores that tasks differ in burden.
- **Reminder fatigue without structure:** ad-hoc reminders don’t match recurrence or accountability.
- **Rigid plans:** static lists break when someone is tired, short on time, or unwilling to do a specific kind of work today.
- **Coordination cost:** negotiating swaps and coverage is emotionally expensive.

---

## 3. Product goals

1. **Make obligations explicit** — who owns what, when, and how much effort it represents.
2. **Make fairness measurable** — compare **effort points**, not raw task counts.
3. **Make execution resilient** — quick toggles reshape *today’s* workload without abandoning the plan.
4. **Support multi-user households** — shared truth, individual accountability, optional roles.
5. **Reduce missed work** — timely notifications aligned to household rhythm.

### 3.1 Non-goals (initial release)

- Full smart-home / IoT integrations.
- Payments, marketplace chore trading, or gamified leaderboards with public profiles.
- Android / web clients (may be future; design data model with portability in mind).

---

## 4. Target users and personas

| Persona | Needs | Product implications |
|--------|--------|----------------------|
| **Household admin** | Onboarding, invites, categories, defaults, dispute resolution | Household settings, roles, audit-friendly history |
| **Adult member** | Assignments, swaps, notifications, fairness visibility | Personal dashboard, points, mood toggles |
| **Teen / older child** | Simplicity, clarity, fewer taps | Simplified “Today” view, large actions |
| **Busy / low-energy days** | Less cognitive load | Mood presets, smart filtering, gentle reshuffle |
| **Conflict-averse member** | Avoid negotiation | Automated swap suggestions, clear rules |

---

## 5. Core concepts (domain model)

### 5.1 Household

- **Single shared space** (one household) containing members, jobs, categories, settings, and history.
- **Membership:** invite-based join; each user belongs to one or more households (future: multi-household; v1 can be single-household-first with clear path to multi).

### 5.2 Member (user)

- Identity tied to **Apple ID** or app account (implementation choice in §12).
- **Display name**, **avatar** (optional), **role** (Admin vs Member), **notification preferences**.
- **Effort ledger:** cumulative points from completed work (see §8).

### 5.3 Job (chore template + instances)

Distinguish:

- **Job definition (template):** name, description, category, default effort rating, recurrence rule, default assignee strategy, estimated duration (optional), attachments/notes (optional future).
- **Job occurrence / instance:** a concrete dated (or undated backlog) unit of work generated from recurrence or manual creation — this is what appears on **Today** vs **Future**, receives **notifications**, and is **completed** or **skipped** with reason.

### 5.4 Category

- **System categories** (optional seed) + **user-defined categories** (unlimited in theory; UX may cap visible list).
- Categories power filtering, reporting, and **mood rules** (“anything except cleaning”).

### 5.5 Effort rating (points)

- Each job (template and/or instance) carries an **effort score** (integer or half-step — product decision).
- **Household default scale** (e.g. 1–5 or 1–10) with labels (e.g. “Light / Medium / Heavy”).
- **Per-job override** always allowed.
- **Optional caps** per day/week per person (fairness guardrails — see §8).

### 5.6 Assignment

- Occurrence has **assigned member(s)** — v1: **single assignee**; future: shared responsibility with partial credit.
- Assignment methods: manual, round-robin, load-balanced by points, “open pool” (anyone can claim).

### 5.7 Mood state (session)

- **Ephemeral user intent** for *right now* (not a permanent profile): presets alter **which occurrences surface** and **suggested order**.
- Does not permanently delete obligations; it **reshuffles presentation and optional reassignment** within policy.

---

## 6. Functional requirements

### 6.1 Onboarding and household lifecycle

| ID | Requirement |
|----|----------------|
| **FR-ONB-1** | First launch: create household or join via invite. |
| **FR-ONB-2** | Admin can set household name, timezone, week start day, default notification window. |
| **FR-ONB-3** | Invite flow: share link and/or short code; pending invites visible to admin. |
| **FR-ONB-4** | Member removal / leave household with data handling policy (see §10). |

### 6.2 Jobs — create, edit, archive

| ID | Requirement |
|----|----------------|
| **FR-JOB-1** | Create job with: title (required), details/notes (optional), category (required or default “Uncategorized”), effort rating (required, default from category or household default). |
| **FR-JOB-2** | Edit all fields; archived jobs stop generating new occurrences but preserve history. |
| **FR-JOB-3** | Optional fields: estimated duration, location/room tag (optional), checklist subtasks (stretch). |
| **FR-JOB-4** | Validation: title max length, effort within allowed scale. |

### 6.3 Custom categories

| ID | Requirement |
|----|----------------|
| **FR-CAT-1** | CRUD: create, rename, merge, delete (with reassignment prompt). |
| **FR-CAT-2** | Optional **category defaults**: default effort, default recurrence template, icon/color for recognition. |
| **FR-CAT-3** | Categories usable in filters, analytics, and mood rules. |

### 6.4 Recurrence and scheduling

| ID | Requirement |
|----|----------------|
| **FR-REC-1** | Supported patterns (MVP): **none**, **daily**, **weekly** (pick days), **monthly** (date or nth weekday), **custom interval** (every N days/weeks). |
| **FR-REC-2** | **End condition:** never, end date, or after N occurrences. |
| **FR-REC-3** | **Timezone-aware** generation: occurrences materialize in household timezone. |
| **FR-REC-4** | **Exceptions:** skip single occurrence; edit one vs edit series (with explicit UX). |
| **FR-REC-5** | **Backlog / unscheduled** jobs allowed (no date until user schedules or mood engine pulls in). |

### 6.5 Today vs future

| ID | Requirement |
|----|----------------|
| **FR-TDY-1** | **Today** view: occurrences with **due date = local calendar today** OR **explicitly snoozed into today** OR **overdue** (policy toggle: show overdue in Today vs separate “Overdue” section). |
| **FR-TDY-2** | **Future** view: occurrences due after today, grouped by week or date. |
| **FR-TDY-3** | **Calendar** view (stretch) with same rules. |
| **FR-TDY-4** | Completing a future occurrence early is allowed (configurable: counts for today’s points or scheduled day). |

### 6.6 Assignment

| ID | Requirement |
|----|----------------|
| **FR-ASN-1** | Manual assign on create/edit occurrence. |
| **FR-ASN-2** | **Default assignee** on template: specific person, rotating, or unassigned pool. |
| **FR-ASN-3** | **Reassignment** with optional reason (for analytics, not blame). |
| **FR-ASN-4** | **Claim** flow for pool tasks: first-claim wins or admin approval (MVP: first-claim). |

### 6.7 Notifications

| ID | Requirement |
|----|----------------|
| **FR-NOT-1** | Request permission with **value-first** pre-prompt explaining what will be notified. |
| **FR-NOT-2** | **Per-occurrence reminders** at user-chosen time(s), e.g. “morning digest,” “evening nudge,” or specific clock time. |
| **FR-NOT-3** | **Recurring notifications** tied to recurrence generation — if the pattern shifts, pending notifications update. |
| **FR-NOT-4** | **Quiet hours** at household and personal level; notifications suppressed or summarized. |
| **FR-NOT-5** | **Digest mode:** one notification summarizing N tasks vs one per task (user setting). |
| **FR-NOT-6** | Deep link opens the relevant occurrence. |
| **FR-NOT-7** | When assignment changes, notify previous and new assignee (optional setting). |

### 6.8 Effort points and fairness

| ID | Requirement |
|----|----------------|
| **FR-PTS-1** | On **complete**, occurrence awards **effort points** to completing user (or split if shared — future). |
| **FR-PTS-2** | **Skip** / **defer** actions: configurable point impact (default: 0 points, affects “completion rate” separately from points). |
| **FR-PTS-3** | **Household balance view:** rolling window (7d / 30d / all time) showing points per member, optional **balance score** (deviation from equal share). |
| **FR-PTS-4** | **Fairness helper (optional):** suggest next assignee for recurring jobs to balance points (admin can enable). |
| **FR-PTS-5** | Transparency: each occurrence shows **why** points value is what it is (inheritance from template/category). |

### 6.9 Mood-based task swapping (flagship)

**Intent:** User selects a **quick mood preset**; app **reshuffles** what they see and optionally **what they’re assigned** among **eligible** tasks so the household still progresses.

#### 6.9.1 Presets (MVP)

| Preset | Meaning | Reshuffle behavior |
|--------|---------|---------------------|
| **Low energy** | Prefer less demanding work today | Rank/surface lower effort first; suggest swapping with higher-effort tasks assigned to others *only if* policy allows and counterpart accepts or auto within trusted rules |
| **Quick tasks only** | Limited time / attention | Filter to tasks under **duration threshold** (user-set default e.g. 10 min) and/or under **effort threshold**; hide or deprioritize the rest for *this user’s session* |
| **Anything except [category]** | Hard avoidance | Exclude category from eligible set; replacement drawn from pool of **unassigned**, **tradeable**, or **same-day flexible** tasks |

| ID | Requirement |
|----|----------------|
| **FR-MOOD-1** | Mood is **per-user**, **session-based**, with optional **expiry** (e.g. until midnight, or 4 hours). |
| **FR-MOOD-2** | **No silent deletion:** hidden tasks remain in household state; other members still see full truth. |
| **FR-MOOD-3** | **Reshuffle modes** (household policy set by admin): **Presentation-only (default):** only changes ordering/suggestions for the user; assignments unchanged. **Auto-swap (opt-in):** system proposes or executes swaps within **constraints** (§6.9.3). **Semi-auto:** user confirms each swap. |
| **FR-MOOD-4** | **Swap eligibility rules** (configurable): Only among **today** and **overdue** (default). Never swap **personal/private** tasks (if ever introduced). Never steal **high-priority** tasks without permission. Respect **skill / age tags** (future). |
| **FR-MOOD-5** | **Counterparty fairness:** if user A dumps high-effort task, system must propose **compensating** trade (effort delta within tolerance) or **point-neutral** exchange. |
| **FR-MOOD-6** | **Conflict resolution:** if two users both choose “quick tasks only,” solver allocates by **shortest task round-robin**, **historical point balance**, or **random** — admin picks algorithm. |
| **FR-MOOD-7** | **Audit trail:** “Mood reshuffle applied” event logged with before/after for disputes (lightweight copy). |

#### 6.9.2 “Solver” product logic (conceptual)

**Inputs:** user mood, their current assigned occurrences today, household pool, constraints, others’ moods.

**Output:** ordered list for user + optional swap transactions.

**Priority objectives (weighted):**

1. Respect hard excludes (category).
2. Respect time/effort caps (quick only).
3. Minimize **net unfairness** (points imbalance across members over window).
4. Maximize **coverage** (reduce probability of zero progress categories piling up).

| ID | Requirement |
|----|----------------|
| **FR-MOOD-8** | If **no eligible tasks** exist under mood filters, show empathetic empty state with **one-tap** actions: “Snooze mood,” “Show all tasks anyway,” “Offer help swap request.” |

#### 6.9.3 Ethics and coercion guardrails

| ID | Requirement |
|----|----------------|
| **FR-MOOD-9** | Auto-swap never assigns **new** work to someone in **Do Not Disturb** / **Away** status (future) without consent. |
| **FR-MOOD-10** | Teen / minor accounts (if detected by age): stricter defaults — **presentation-only**, no auto-swap. |

---

## 7. Key user journeys (narrative acceptance criteria)

### 7.1 Admin creates household and first jobs

1. Admin creates household, sets timezone.
2. Creates categories (e.g. Cleaning, Kitchen, Admin).
3. Adds job “Vacuum living room,” category Cleaning, effort 4, weekly Sun, assigns rotating.
4. **Acceptance:** Next Sunday occurrence exists, appears in Future until due week, then Today on Sunday; notification fires per settings.

### 7.2 Member joins and completes work

1. Member joins via invite, enables notifications.
2. Sees Today list with points on each card.
3. Completes task; points accrue; household balance updates.
4. **Acceptance:** Completion timestamp recorded; recurrence generates next instance.

### 7.3 Low-energy day

1. User enables **Low energy**.
2. Their Today list reorders; optional swap offers appear.
3. User accepts swap: gives “Deep clean bathroom” (effort 5), receives “Unload dishwasher” (effort 2) from pool/trusted auto.
4. **Acceptance:** Assignments update; both users notified; ledger shows fair exchange within tolerance.

### 7.4 “Anything except cleaning”

1. User selects exclude **Cleaning**.
2. Cleaning tasks hidden from their session; replacement tasks drawn per policy.
3. **Acceptance:** No cleaning tasks auto-reassigned to them without explicit override; household still has cleaning coverage (surface alert if coverage gap).

---

## 8. Effort points — detailed rules

- **Scale:** household-configurable; recommend **1–5** MVP with optional decimals later.
- **Inheritance order:** occurrence override > template > category default > household default.
- **Completion:** full points to completer; partial completion (checklist future) could award partial.
- **Balance metrics:**
  - **Share of effort:** user points / household points in window.
  - **Expected share:** based on days active in household or agreed weighting (advanced: “availability weights”).
- **Fairness modes (settings):**
  - **Informational only** (default): show balance, no automation.
  - **Suggestive:** nudges when assigning.
  - **Automated balancing** for rotating chores (stretch).

---

## 9. Information architecture (screens)

1. **Today** — primary home; mood bar; filters; completion CTA.
2. **Future** — grouped upcoming; drag-to-reschedule (stretch).
3. **Jobs** — templates library; add/edit.
4. **Categories** — manage from Jobs or dedicated settings.
5. **Household** — members, invites, roles, fairness settings, mood policies.
6. **Me / Profile** — notification prefs, personal digest schedule, points history.
7. **Activity / History** — completions, skips, swaps (transparency).

**Navigation:** tab bar: Today | Future | Jobs | Household (or Jobs inside Household for simplicity in MVP).

---

## 10. Data, privacy, and compliance

- **Data minimization:** store only what’s needed for chores and fairness.
- **Household data isolation:** strict tenancy; members only see their household(s).
- **Deletion:** leaving household — remove PII association; retain anonymized aggregates vs full delete (legal/product choice).
- **Child accounts:** if under 13, follow **COPPA** / parental controls (likely require adult-managed household).
- **Export:** optional CSV of jobs/history (stretch).

---

## 11. Non-functional requirements

| Area | Requirement |
|------|-------------|
| **Platform** | Native SwiftUI (recommended), iOS version target TBD (support N-1 major). |
| **Offline** | View Today/Future and mark complete offline; sync when online; conflict policy (last-write-wins vs server authority) must be documented. |
| **Performance** | Today loads <1s on mid-tier device for ≤500 active occurrences. |
| **Accessibility** | Dynamic Type, VoiceOver labels on points and mood toggles, Reduce Motion respects alternative transitions. |
| **Localization** | Architect for strings; MVP English. |
| **Security** | Encrypted transport; secure invite tokens; role checks server-side. |
| **Notifications** | UNUserNotificationCenter; handle permission denial gracefully. |
| **Analytics** | Privacy-preserving, opt-in; core funnels only. |

---

## 12. Technical considerations (for engineering handoff, not build spec)

- **Backend:** almost certainly required for **multi-user sync**, invites, authoritative occurrence generation, and swap transactions.
- **Recurrence engine:** server-generated instances avoid clock skew across devices.
- **Push vs local:** local for simple; **push** for household updates and swaps when app inactive.
- **Sign-in:** Sign in with Apple + household mapping.

---

## 13. MVP scope vs roadmap

### MVP (v1)

- Household + invites + roles (basic).
- Jobs + categories + effort + assignments.
- Recurrence (daily/weekly at minimum).
- Today / Future.
- Notifications + quiet hours + digest (basic).
- Points ledger + simple balance chart.
- Mood presets: **presentation-only** + **manual swap suggestions** (user confirms).

### v1.1

- Auto-swap with policies + audit log.
- Monthly recurrence + exceptions UX polish.
- Per-category “coverage warnings.”

### v2+

- Multi-household per user, widgets, Siri shortcuts, Apple Watch glance, shared tasks with split points, smart fairness based on availability calendar.

---

## 14. Success metrics (KPIs)

- **WAU / household** and **retention** at 4 weeks.
- **Tasks completed per household per week** + **points Gini coefficient** or simpler **std dev of points** trending down (fairness).
- **Notification opt-in rate** and **tap-through to complete**.
- **Mood feature usage** and correlated **same-day completion rate**.
- **Support burden:** swaps disputes per 1000 users.

---

## 15. Risks and mitigations

| Risk | Mitigation |
|------|------------|
| Mood swaps feel unfair | Conservative defaults, audit trail, optional approval |
| Notification spam | Digest + quiet hours + caps |
| Complexity overwhelms users | Progressive disclosure; strong Today-first UX |
| Recurrence edge cases (DST, month-end) | Server-side generation + tests |
| Household conflict | Neutral language, transparency, no “shame” framing in UI |

---

## 16. Open questions for stakeholder sign-off

1. **Single vs multi-household** in v1?
2. **Skip/defer** impact on fairness metrics and recurring next occurrence.
3. **Auto-swap** default: off vs on for new households?
4. **Overdue** behavior: indefinite carry or auto-reassign after X days?
5. **Points for chores done “for” someone else** (covering) — explicit flow?
6. **Monetization** (if any): freemium vs one-time purchase affects sync/backend scope.

---

*This PRD is written to support derivation of epics → user stories → acceptance criteria without ambiguity on flagship differentiators (**effort-based fairness** and **mood-based reshuffling with guardrails**).*
