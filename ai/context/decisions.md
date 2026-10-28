# docusaurus — decisions

The choices that shape this repository, one line each, with where the full
reasoning lives. Superseded decisions stay listed, marked, so the history
reads in order.

| # | Decision | Why | Source |
|---|---|---|---|
| 1 | A static build served as Workers Static Assets behind one Worker; no adapter | Docusaurus builds every route to files; nothing renders at request time | design.md, "The alternative rejected" |
| 2 | Docusaurus 3.10.2, not the template's 2.0.1 | The brief asks for Docusaurus 3; the template's docs and posts build under MDX 3 unchanged | design.md, "Docusaurus 2 → 3"; risk DS-C |
| 3 | The docs and the blog under `apps/web/content/` | `apps/web/docs/` is the component's generated catalog pages, which Docusaurus would publish | design.md, "The repository" |
| 4 | Links without a trailing slash, served by `html_handling: drop-trailing-slash` | Docusaurus's default `trailingSlash`; every link answered without a redirect | risk DS-F |
| 5 | Each deploy builds for its own origin (`PUBLIC_SITE_URL`: `SITE_URL`, else workers.dev) | Canonical links, the sitemap and the feeds are absolute | risk DS-E |
| 6 | The site's name and repository are one seam, `apps/web/site.js`; the config reads them | One place a product's identity is written | IMPLEMENTATION-STATUS, departure 4 |
| 7 | The framework's own names are masked from the rename; the identity's Pascal form is `DocusaurusBaseline` | The slug is the framework's name; renaming its packages breaks the build | design.md, "The framework's name is the slug"; risk DS-B |
| 8 | No infra root: the site binds nothing | Nothing to provision; `infra/` and `packages/` stay as empty discovery roots | README |
| 9 | One landing (`01-product`) then the record (`03-docs`); each bootstrap pull request checked in the box | A landing has a fixed cost; the convergence on main builds, deploys and smoke-tests the site for real (nextra-docs, cirrus-baseline baseline-v22) | `repo-blueprint.yaml` |
| 10 | stack-tectonic 0.19.0, not 0.20.0 | The siblings' pin; 0.20.0's lane-shared install is a layout this build has not been verified in | risk DS-G |
| 11 | No search | The template has none; Docusaurus's needs keys a site applies for | risk DS-H |
| 12 | Component docs are generated from the manifests and checked in CI | A hand-written copy of the component's facts drifts silently | `tooling/catalog/gen-component-docs.py` |
