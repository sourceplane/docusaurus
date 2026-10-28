# Epics

Orun-style work programs. Each epic is a folder carrying `epic.yaml` (the
declaration the platform reads: slug, key prefix, milestones with exit
criteria and task keys) beside its doc set. The pull request that adds the
folder is the adoption; the merge creates the epic in the workspace.

| Epic | Cluster | Status | What it is |
|------|---------|--------|------------|
| [`docusaurus/`](./docusaurus/) | **DS** | In progress (DS0) | Vercel's Docusaurus template — a docs site and blog, moved to Docusaurus 3 — built static and served as Cloudflare Workers Static Assets behind one Worker, and an Orun baseline that instantiates it (DS2) |

As-built ≠ intent: what shipped lives in each epic's `IMPLEMENTATION-STATUS.md`.
