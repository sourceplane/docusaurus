# docusaurus

A documentation site and blog — a tutorial of Markdown and MDX docs with a
generated sidebar, a blog with tags, authors, an archive and RSS and Atom
feeds, a React home page, dark mode and code highlighting — built with
[Docusaurus](https://docusaurus.io) 3, fully static, and served as
**Cloudflare Workers + Static Assets** behind one small Worker.

## Live deployment

<!-- 03-docs:begin -->
Not recorded yet. The bootstrap's last phase writes the live URLs, the
workspace and the secrets the site uses into
[ai/context/deployment.md](ai/context/deployment.md); how the site deploys
and how to operate it is in
[ai/context/operations.md](ai/context/operations.md).
<!-- 03-docs:end -->

## What is here

| Surface | Where |
|---|---|
| The site's name and the repository its GitHub and "Edit this page" links point at | `apps/web/site.js` |
| The config: title, tagline, navbar, footer, the docs and blog plugins, code themes | `apps/web/docusaurus.config.js` |
| The docs (Markdown and MDX; the sidebar is generated from the folders) | `apps/web/content/docs`, `apps/web/sidebars.js` |
| The blog posts and their authors | `apps/web/content/blog` |
| The home page, a Markdown page and the React components they use | `apps/web/src/pages`, `apps/web/src/components` |
| The site's styles | `apps/web/src/css/custom.css` |
| Images and other files served as they are | `apps/web/static` |
| The Worker in front of the static files, and the deploy contract | `apps/web/worker/index.ts`, `apps/web/wrangler.jsonc`, `apps/web/component.yaml` |
| Tests | `tests/web` (vitest) |

## Getting started

```bash
pnpm install
pnpm typecheck
pnpm lint
pnpm test
pnpm build            # docusaurus build → apps/web/build
```

```bash
pnpm --filter @app/web dev        # http://localhost:3000, reloading as you edit
pnpm --filter @app/web preview    # wrangler dev over the built site, as the Worker serves it
```

Write a doc by dropping a Markdown or MDX file into `apps/web/content/docs/`
(a folder becomes a sidebar category; `_category_.json` and a page's
`sidebar_position` order them), and a post by dropping one into
`apps/web/content/blog/`. Every page is pre-rendered at build time, and a
path that is not a page is the site's 404. Make the site yours in
`apps/web/content/` (the docs and the blog), `apps/web/src/pages/` (the home
page), `apps/web/docusaurus.config.js` (the tagline, the navbar and the
footer's links) and `apps/web/site.js` (its name and repository).

## How it deploys

Merges to `main` converge through [Orun](https://github.com/sourceplane/orun):
`.github/workflows/ci.yml` plans the changed components and runs each lane
against the workspace in `intent.yaml`. The site deploys to `stage`, then to
`prod` once stage has converged on the same commit; `dev` only verifies. The
Worker is `docusaurus-web-<env>` on your account's workers.dev subdomain,
and every deploy is smoke-tested over HTTP: the home page and the tutorial's
first page must render, the blog's feed must be served, and an unknown path
must answer the site's 404. A pull request runs the same pipeline's verify
lanes: the site built and dry-deployed for each environment, with nothing
deployed. They do not lint or run the tests, so run `pnpm typecheck`,
`pnpm lint` and `pnpm test` before you push. (A push to `main` builds,
deploys and smoke-tests.)

The pipeline holds one credential, GitHub's own `GITHUB_TOKEN`. The
Cloudflare token and account id are brokered per run from the workspace's
Cloudflare connection; nothing provider-shaped is stored in the repository
or in GitHub.

**Deploy by hand.** Orunbase's **Deploy** button on a component, or **Run
workflow** on the CI workflow in GitHub's Actions tab (on `main`), runs
`ci.yml` for the environment and components you pick, and each one deploys
exactly as a merge would deploy it. Leave the component blank to redeploy
every component in that environment, with nothing changed: after rotating a
secret, say. A component with nothing to run in that environment (a test
suite in `prod`) is left out with a notice.

## Custom domain

The site answers on workers.dev from its first deploy. To serve it on your
own domain:

1. Add the domain to the Cloudflare account the site deploys into, and attach
   it to the Worker (dashboard → Workers & Pages →
   `docusaurus-web-prod` → Settings → Domains & Routes → Add →
   Custom domain). Do the same for stage with a subdomain if you want one.
2. Record the environment's public origin in `intent.yaml`: the deploy
   builds the site's canonical links, sitemap and the blog's RSS and Atom
   feeds for it (until then they name the workers.dev URL), and the
   deployment record probes it beside the workers.dev URL:

   ```yaml
   environments:
     prod:
       env:
         SITE_URL: https://docusaurus.example.com
   ```

   The site was born with the reserved placeholder `docusaurus.example.com`
   where its domain goes: that example, and `BASE_DOMAIN` under each
   environment (dev, stage and prod) in `intent.yaml`. Replace it with your
   domain in the same change, and land it with a change under `apps/web` so
   the merge rebuilds the site.

## Credits

The site is Vercel's Docusaurus example
([vercel/examples](https://github.com/vercel/examples),
`framework-boilerplates/docusaurus-2`, © Vercel, MIT-licensed —
`apps/web/LICENSE.md`), itself the classic template Docusaurus's own
scaffolder writes, moved to Docusaurus 3. Its tutorial and blog posts
describe Docusaurus and link to its documentation; replace them with your
own content as you make the site yours.
