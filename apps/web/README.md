# apps/web — the docs site

A documentation site and blog on [Docusaurus](https://docusaurus.io) 3 — the
classic template, as Vercel's Docusaurus example
(MIT, `LICENSE.md`) ships it — built fully static and served as Cloudflare
Workers + Static Assets:

- a tutorial of Markdown and MDX docs in `content/docs`, its sidebar
  generated from the folders (`sidebars.js`, each folder's
  `_category_.json`)
- a blog in `content/blog` — posts with tags, authors (`authors.yml`), an
  archive and RSS and Atom feeds
- a React home page and a Markdown page in `src/pages`
- dark mode, code highlighting (Prism) and "Edit this page" links

The docs and the blog live under `content/` rather than Docusaurus's default
`docs/` and `blog/`: `docs/` beside this file is the component's own catalog
pages (overview, architecture, runbook), which are not pages of the site.

The site's name and the repository its GitHub and "Edit this page" links
point at are in `site.js`; `docusaurus.config.js` reads them, and the
site's public origin from `PUBLIC_SITE_URL` (the deploy sets it per
environment).

```bash
pnpm dev        # docusaurus start on http://localhost:3000
pnpm build      # docusaurus build → build/
pnpm preview    # wrangler dev over the built site, behind worker/index.ts
```

How it is deployed — per environment, on merge to `main` — is the
repository's README and `component.yaml` beside this file.
