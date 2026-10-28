# docusaurus — Vercel's Docusaurus template on Cloudflare Workers

**Docusaurus builds fully static, so the port is two things: the template
moved from Docusaurus 2 to Docusaurus 3, and where it is served — `build/` as
Cloudflare Workers Static Assets behind one small Worker, deployed by Orun to
stage and prod on every merge — and then the baseline that makes a copy of
it somebody else's docs site in one landing.**

| | |
|---|---|
| Status | ✅ Shipped (`baseline-v1`) — proven offline in Baseline CI; not yet live (risk DS-A) |
| Upstream | [vercel/examples](https://github.com/vercel/examples) `framework-boilerplates/docusaurus-2` (MIT), at `de86723` (2026-10-16): Docusaurus 2.0.1's classic template |
| Reference | [nextra-docs](https://github.com/sourceplane/nextra-docs) — the same docs-site scaffolding, tests and bootstrap; [astro-paper](https://github.com/sourceplane/astro-paper) — the same static build behind one Worker |
| Key | `DS` |

## Read in this order

1. [design.md](design.md) — the template, the move to Docusaurus 3, how each
   Vercel piece maps to Cloudflare, the repository, why the framework's own
   names are masked from the rename, the build, and the alternative rejected.
2. [implementation-plan.md](implementation-plan.md) — the milestones and
   what each one lands.
3. [risks-and-open-questions.md](risks-and-open-questions.md) — what is not
   proven, and what was accepted.
4. [IMPLEMENTATION-STATUS.md](IMPLEMENTATION-STATUS.md) — what shipped, and
   every departure from the upstream template.

## Milestones

| Milestone | What it lands | Task |
|---|---|---|
| DS0 — the spec | the repository, its intent, CI, tooling and spec index; this doc set | DS-1 |
| DS1 — the docs site on Workers | the template on Docusaurus 3 in `apps/web`, built static, served as assets behind one Worker, with its tests | DS-2 |
| DS2 — a baseline | the console card, the build document, the context pack and the baseline's tests | DS-3 |
