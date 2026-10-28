# docusaurus — where this repository stands

The entry page for anyone (or any agent) picking this repository up. It is
this repository's own state and does not ship to a site built from it; the
two pages that do are [operations.md](operations.md) and
[deployment.md](deployment.md).

## What it is

Vercel's Docusaurus template — Docusaurus's classic template: a tutorial of
docs, a blog, a React home page — moved from Docusaurus 2 to Docusaurus 3,
built fully static and served as Cloudflare Workers Static Assets behind one
Worker, packaged as an Orun baseline: `orun new --blueprint
repo-blueprint.yaml` builds a new docs site in its own repository and takes
it to live on stage and prod in one landing (`01-product`), then records
what went live (`03-docs`).

## Release

| | |
|---|---|
| Latest tag | `baseline-v1` — DS0–DS2: the template on Docusaurus 3 on Workers, and the baseline |
| Proven live | No — proven offline in Baseline CI only (risk DS-A) |

## Where to read

| Question | Page |
|---|---|
| What shipped, and every departure from upstream | `specs/epics/docusaurus/IMPLEMENTATION-STATUS.md` |
| Why it is built this way | [decisions.md](decisions.md), then `specs/epics/docusaurus/design.md` |
| What could still go wrong | [open-risks.md](open-risks.md), then `specs/epics/docusaurus/risks-and-open-questions.md` |
| How to instantiate it | `BOOTSTRAP.md`, `docs/phases/` |
| What each component is | `apps/web/docs/`, `tests/web/docs/` (generated; `python3 tooling/catalog/gen-component-docs.py`) |

## Next

1. Bootstrap one site from `baseline-v1` from the console, and record its
   timings against the 5-minute estimate (closes DS-A).
