# docusaurus — design

## The template

Vercel's Docusaurus example (`framework-boilerplates/docusaurus-2` in
[vercel/examples](https://github.com/vercel/examples)) is Docusaurus's own
classic template as `create-docusaurus` 2.0.1 wrote it: a tutorial of nine
Markdown and MDX docs in two categories (`docs/`, the sidebar generated from
the folders by `sidebars.js`, ordered by `_category_.json` and each page's
`sidebar_position`), a blog of four posts with tags, authors (`authors.yml`)
and an archive, a React home page with three features and a Markdown page
(`src/pages`), the classic theme's navbar, footer, dark mode and Prism code
highlighting. Its config is `docusaurus.config.js`; its title is "My Site".

It is static: `docusaurus build` writes every route to `build/` — each page
as `<path>/index.html`, linked without a trailing slash (the default
`trailingSlash`), with the blog's RSS and Atom feeds, a sitemap and
`404.html`. Vercel serves it with its Docusaurus framework preset.

## Docusaurus 2 → 3

The brief asks for Docusaurus 3. The template moves to 3.10.2 the way
Docusaurus's own migration guide and its 3.10.2 classic template describe:
React 19, MDX 3 (`@mdx-js/react` 3), `clsx` 2, `prism-react-renderer` 2
(whose themes are `themes.github` and `themes.dracula`), an ESM config,
plain-string paths, and `onBrokenMarkdownLinks` under `markdown.hooks`. The
template's own docs and posts build under MDX 3 unchanged. Nothing else of
the 3.x template is taken (its `future.v4` flag, its social card, its new
blog options): the site is the 2.0.1 template, on 3.

## How it maps to Cloudflare

| Vercel | Here | Why |
|---|---|---|
| Static output on Vercel's CDN | `build/` as Workers Static Assets, uploaded with `<repo>-web-<env>` | The site is static; the assets are the site |
| — | One Worker, `apps/web/worker/index.ts`, hands unmatched requests to the assets | The `cloudflare-workers-assets-turbo` composition deploys a Worker with its assets; a request no file matches reaches it and gets the site's 404 |
| Clean URLs: `/docs/intro` for `docs/intro/index.html` | `assets.html_handling: drop-trailing-slash` | It serves `<path>/index.html` at `<path>` — the link Docusaurus renders — and redirects `<path>/` there; no change to Docusaurus's `trailingSlash` |
| The host's 404 | `not_found_handling: 404-page` → `build/404.html` with a 404 | Docusaurus's own 404 page |
| `url: https://your-docusaurus-test-site.com` | `PUBLIC_SITE_URL` per deploy: the environment's `SITE_URL`, else its workers.dev URL; `http://localhost:3000` for a local build | Canonical links, the sitemap and the feeds need an origin at build |

## The repository

The same as nextra-docs', with astro-paper's static build: `apps/web` is the
site (type `cloudflare-workers-assets-turbo`, lane `isolated`, deployed on
stage and prod on a push to `main`, verified on dev and on pull requests),
`tests/web` its vitest suite, and there is no infrastructure: no database,
no bucket, no runtime secret. The site's name and repository are one seam,
`apps/web/site.js` (`SITE_NAME`, `SOURCE_URL`), which `docusaurus.config.js`
reads: the title, the navbar, the footer, the GitHub links and every "Edit
this page" link (`<SOURCE_URL>/tree/main/apps/web/`, so a docs page edits
`apps/web/content/docs/<page>.md` in the site's own repository).

The docs and the blog live under `apps/web/content/`, not Docusaurus's
default `docs/` and `blog/`: every component's `docs/` holds its generated
catalog pages (overview, architecture, runbook), and Docusaurus would publish
them as pages of the site. The URLs do not change.

## The framework's name is the slug

This baseline is `docusaurus`, and so is everything the framework names
after itself: its packages and client modules (`@docusaurus/core`,
`@docusaurus/Link`), its CLI (`docusaurus build`), its config file
(`docusaurus.config.js`), its generated directory (`.docusaurus/`), its CSS
variables (`--docusaurus-highlighted-code-line-bg`), its homes
(docusaurus.io, facebook/docusaurus) and the template's community links. The
rename's repo-slug rule would rename every one of them and break the build,
so the rename engine masks them (`FRAMEWORK` in `tooling/rebrand/rebrand.mjs`),
each spelling exactly, and allows them in the leftover sweep. In the
template's own docs and posts under `apps/web/content` — a tutorial about
Docusaurus, posts by its team, a `docusaurus` tag and a banner image named
for it — the framework's name in either case is masked too
(`TEMPLATE_WRITING`). Everywhere else a lowercase `docusaurus`,
`docusaurus-` or `DOCUSAURUS_` is the baseline's identity: renamed, or a
leftover that fails the sweep.

The identity's Pascal form is `DocusaurusBaseline`, not `Docusaurus`: the
framework's name in prose (the READMEs, the footer's "Built with
Docusaurus", the home page's "Docusaurus Tutorial") is not the site's, and a
sweep for it would fail every page that names the framework. As docus does,
the sweep looks for a code form nothing here spells, so one that does still
fails.

Two checks hold it: `testing/rebrand.test.sh` (every masked spelling, and the
leftovers that must still fail), and the placement tier, which fails on any
placed file spelling one of the framework's names with the site's
(`@acme-docs/`, `acme-docs build`, `.acme-docs/`, …). The e2e caught the
first version of the package mask missing `@docusaurus/Link`, a capital
letter the mask's class left out: the build could not resolve
`@acme-docs/Link`.

## The build

`repo-blueprint.yaml` is nextra-docs': one landing (`01-product`) places,
brands and lands the whole tree, one convergence builds and deploys stage
and prod side by side, and `03-docs` records what went live. The smoke
checks that the home page is the template's, that `/docs/intro` renders,
that the blog's RSS feed is served, and that an unknown path is a 404.

## Out of scope

- Search: the template has none, and Docusaurus's (Algolia DocSearch) needs
  keys a site applies for.
- Translations and versioned docs: the tutorial documents both; the site
  ships one locale and one version, as upstream.

## The alternative rejected

**Next.js through OpenNext, as nextra-docs is built.** The reference's
machinery assumes a server bundle; Docusaurus has none. Running it through an
adapter would add a server entry nothing calls for a site that is files. A
static build with a Worker in front of it is what Docusaurus is.
