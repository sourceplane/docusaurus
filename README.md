# docusaurus

Vercel's [Docusaurus](https://github.com/vercel/examples/tree/main/framework-boilerplates/docusaurus-2)
template — a documentation site and blog: a tutorial of Markdown and MDX docs
with a sidebar generated from its folders, a blog with tags, authors, an
archive and RSS and Atom feeds, a React home page, dark mode and code
highlighting — moved from Docusaurus 2 to Docusaurus 3, running on
**Cloudflare Workers + Static Assets**, deployed by
[Orun](https://github.com/sourceplane/orun) to stage and prod on every merge.
Packaging it as an Orun baseline is the next milestone (DS2).

Docusaurus builds fully static: `docusaurus build` writes every docs page,
blog post, tag page and archive, the feeds, the sitemap and the 404 page to
`build/`. That folder is uploaded as Workers Static Assets with one small
Worker in front for what matches no file; no adapter and no server code. The
docs, the blog, the home page and the theme do not change; the site's name
and repository move into one module, the docs and the blog move under
`content/`, and each deploy builds for its own origin. See
[`specs/epics/docusaurus`](specs/epics/docusaurus/README.md) for the design,
the milestones and the as-built status.

## What is here (the site)

| Surface | Where |
|---|---|
| The site's name and the repository its GitHub and "Edit this page" links point at | `apps/web/site.js` |
| The config: title, tagline, navbar, footer, the docs and blog plugins, the origin | `apps/web/docusaurus.config.js` |
| The docs and the blog (Markdown and MDX) | `apps/web/content/docs`, `apps/web/content/blog` |
| The home page, a Markdown page and their components, the styles | `apps/web/src` |
| The Worker in front of the assets, its config, deploy contract | `apps/web/worker/index.ts`, `apps/web/wrangler.jsonc`, `apps/web/component.yaml` |
| Tests (the name seam, the config, the Worker's assets, the content) | `tests/web` (vitest) |

## Getting started

```bash
pnpm install
pnpm typecheck        # tsc: the config and sidebars (`// @ts-check`) and the Worker
pnpm lint             # eslint
pnpm test             # vitest
pnpm build            # docusaurus build → apps/web/build
```

```bash
pnpm --filter @app/web dev        # docusaurus start on http://localhost:3000
pnpm --filter @app/web preview    # wrangler dev over the built site and its Worker
```

## How it maps to Vercel

| Vercel | Here |
|---|---|
| Static output (`build/`) on Vercel's CDN, from its Docusaurus framework preset | Workers Static Assets: `build/` uploaded with the Worker `<repo>-web-<env>` (`apps/web/wrangler.jsonc`) |
| The template's build (`docusaurus build`) | Unchanged: `docusaurus build` (Docusaurus 3.10.2), through turbo |
| Clean URLs (`/docs/intro` for `docs/intro/index.html`) | `assets.html_handling: drop-trailing-slash` — `/docs/intro` serves `docs/intro/index.html`, `/docs/intro/` redirects to it — the links Docusaurus renders (its default `trailingSlash`) are answered directly |
| The host's 404 for an unknown path | the Worker hands it to the assets, which answer `build/404.html` with a 404 (`not_found_handling: 404-page`) |
| `url: https://your-docusaurus-test-site.com` | Each deploy builds for its own origin — the environment's `SITE_URL`, else its workers.dev URL — through `PUBLIC_SITE_URL`, so canonical links, the sitemap and the feeds name the site where it is served |
| Deploy on push | Orun deploys `<repo>-web-{stage,prod}` on merge to `main` (`apps/web/component.yaml`) |
| "Deploy with Vercel" (clone the template) | `orun new --blueprint repo-blueprint.yaml` — a new repository, branded, deployed |

## CI

| Workflow | What it runs | Ships to a site |
|---|---|---|
| `ci.yml` | the Orun pipeline, and the only workflow a site carries: `orun plan --changed`, then one job per lane. A pull request runs the verify lanes (the site built and dry-deployed per environment; the tests' `quick-check` lane installs and checks the package, it does not run them), except the bootstrap's own landings (`orun/BASE-*`), where `plan` alone is the check; a merge deploys stage → prod. It plans nothing while `intent.yaml` names the placeholder workspace `ws_CHANGE_ME`, as this repository does. A manual run (Orunbase's Deploy button, or Run workflow on `main`) plans the environment and components it names under the push-to-main trigger, so they deploy as a merge deploys them | yes |

## Credits

The site is Vercel's Docusaurus example
([vercel/examples](https://github.com/vercel/examples),
`framework-boilerplates/docusaurus-2`, © Vercel, MIT — `apps/web/LICENSE.md`),
itself Docusaurus's classic template, at vercel/examples `de86723`.
