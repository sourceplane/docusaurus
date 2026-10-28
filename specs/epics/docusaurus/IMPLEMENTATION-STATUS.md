# docusaurus — implementation status

| Milestone | State | Landed |
|---|---|---|
| DS0 — the spec | ✅ | the repository's first commit and DS-1 |
| DS1 — the docs site on Workers | ✅ | DS-2 |
| DS2 — a baseline | planned | DS-3 |

## Departures from the upstream template

Everything not listed here is the template as it is in vercel/examples at
`de86723` (`framework-boilerplates/docusaurus-2`).

| # | What | Why |
|---|---|---|
| 1 | Docusaurus 2.0.1 → 3.10.2 (`@docusaurus/core`, `preset-classic`, `module-type-aliases`, plus `@docusaurus/types` and `@docusaurus/tsconfig`); React 17 → 19, `@mdx-js/react` 1 → 3, `clsx` 1 → 2, `prism-react-renderer` 1 → 2 | The brief asks for Docusaurus 3; these are the versions Docusaurus 3's own classic template pins |
| 2 | `docusaurus.config.js` is ESM (`import`, `export default`), the code themes are `prism-react-renderer` 2's `themes.github` / `themes.dracula`, the CSS and sidebar paths are plain strings, and `onBrokenMarkdownLinks` moved to `markdown.hooks` | Docusaurus 3's config form; 3.9 deprecated the top-level option |
| 3 | The docs and the blog live under `content/docs` and `content/blog` (`docs.path`, `blog.path`); the URLs are unchanged (`/docs/…`, `/blog/…`) | `apps/web/docs/` is the component's generated catalog pages, which must not become pages of the site |
| 4 | `site.js` holds the site's name (`SITE_NAME = "My Site"`, the template's title) and its repository (`SOURCE_URL`); the config reads both: the title, the navbar title and logo alt text, the footer's copyright | One rename seam |
| 5 | The navbar's and the footer's GitHub links and every "Edit this page" link (`editUrl`, docs and blog) point at the site's own repository (`<SOURCE_URL>/tree/main/apps/web/`), not facebook/docusaurus | A product edits its own pages |
| 6 | The copyright reads `Copyright © <year> <SITE_NAME>. Built with Docusaurus.` (upstream: "My Project, Inc.") | The site's name, from the seam |
| 7 | `url` is `PUBLIC_SITE_URL` when a deploy sets it, else `http://localhost:3000` (upstream: `https://your-docusaurus-test-site.com`); `organizationName` / `projectName` (GitHub Pages deploy settings) are not carried | Each deploy builds for its own origin; the site does not deploy to GitHub Pages |
| 8 | The package scripts keep the template's (`docusaurus`, `start`, `build`, `serve`, `clear`, `swizzle`, `write-translations`, `write-heading-ids`) — the tutorial names them — `deploy` (GitHub Pages) is dropped, and `dev` (`docusaurus start` on port 3000), `preview` (`wrangler dev`), `typecheck` (`tsc`: the `// @ts-check` config and sidebars, and the Worker) and `lint` (`eslint .`) are added | The workspace's `dev` / `typecheck` / `lint` / `test` / `build` contract |
| 9 | `wrangler.jsonc` names the Worker `<repo>-web`, with `main: ./worker/index.ts`, the `ASSETS` binding over `build/`, `html_handling: drop-trailing-slash` and `not_found_handling: 404-page`; `worker/index.ts` is the Worker | The composition deploys a Worker with its assets; Docusaurus links each page without a trailing slash and writes it as `<path>/index.html` |
| 10 | `engines` (`node: 22.x`) is the workspace's (`>=22`); the template's browserslist is kept | One Node floor for the workspace |
| 11 | Tests: `tests/web` (vitest) — the name seam and where the config reads it, the edit links, the origin, the Worker's assets config, the template's docs, sidebar and blog | The template ships none |
| 12 | `.docusaurus/`, `.cache-loader/` and `build/` are ignored by git, the blueprint and the leak gate | What a build generates is a build's, not the site's |
| 13 | The blog's warnings Docusaurus 3 added (an inline author, posts without a truncation marker) are left as warnings | The template's content as it was; a site writing its own posts sees the advice |
