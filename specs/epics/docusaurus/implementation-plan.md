# docusaurus — implementation plan

Three milestones, each one reviewed pull request (DS0 follows the
repository's first commit), each green before it merges.

## DS0 — the spec (DS-1)

The repository is born: `intent.yaml` with the placeholder workspace
`ws_CHANGE_ME`, `ci.yml` (byte for byte nextra-docs', turso-starter's but for
one comment, which plans nothing until the workspace is set), the shared
TypeScript and ESLint configuration, the spec index, this doc set and the
task contracts.

## DS1 — the docs site on Workers (DS-2)

- The template's `docs/`, `blog/`, `src/`, `static/`, `sidebars.js` and
  `babel.config.js` in `apps/web`, the docs and the blog under `content/`,
  its dependencies in `apps/web/package.json` at Docusaurus 3.10.2.
- `docusaurus.config.js` in Docusaurus 3's form, reading the site's name and
  repository from `site.js` and its origin from `PUBLIC_SITE_URL`; the edit
  and GitHub links to the site's own repository.
- `worker/index.ts` and `wrangler.jsonc`: the Worker in front of `build/`,
  links without a trailing slash, the 404 page.
- `component.yaml`: the deploy contract and its smoke over `/`,
  `/docs/intro`, the blog's feed and a 404.
- Tests (`tests/web`): the name seam and where the config reads it, the edit
  links, the origin, the Worker's assets config, the content.
- The README's "How it maps to Vercel".

## DS2 — a baseline (DS-3)

nextra-docs' machinery, renamed: `blueprint.yaml`, `repo-blueprint.yaml`,
`.baseline/` (identity, product README, task contracts), `tooling/rebrand`
(with the framework's own names masked: its packages and modules, CLI,
config file, generated directory, CSS variables, homes, and its name in the
template's docs and posts), `tooling/bootstrap`,
`hooks/render-deployment-docs.sh` (astro-paper's, probing `/`,
`/docs/intro`, the blog's feed and each `SITE_URL`), `docs/phases/`, the
context pack, `testing/` (the leak and placement gates on this tree's files,
placement also failing on any framework name renamed; the e2e tier building
the site in the stage lane's staged tree and reading every route it
promises) and `baseline.yml` / `tag.yml`.
