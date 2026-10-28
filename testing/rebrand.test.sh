#!/usr/bin/env bash
# THE REBRAND WRITES EACH VALUE ONCE, AND WHAT IT WROTE STAYS WRITTEN.
#
# Drives the real tooling/rebrand/rebrand.mjs over one-file trees and compares
# the file. Each case is a shape this baseline's identity actually takes in the
# tree — the source link, the site-name seam, the worker name, the placeholder
# domain, a secret ref — and each runs through as many passes as a bootstrap
# makes (every phase re-runs the rebrand over everything already placed), so a
# value written by an early phase must survive every later one unchanged.
#
# The identity is PINNED (fixtures/baseline-identity.docusaurus.json)
# rather than read from .baseline/identity.json: what this tests is the engine,
# and its fixtures spell the identity out literally.
#
# Needs: node, git. No network.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
rebrand="$here/../tooling/rebrand/rebrand.mjs"
identity="$here/fixtures/baseline-identity.docusaurus.json"

fail=0
# check NAME VALUES-JSON FILE CONTENT WANT [PASSES]
check() {
  local name="$1" values="$2" file="$3" content="$4" want="$5" passes="${6:-1}"
  local tmp got out i
  tmp="$(mktemp -d)"
  git -C "$tmp" init -q
  mkdir -p "$tmp/$(dirname "$file")" "$tmp/.rebrand"
  printf '%s\n' "$content" > "$tmp/$file"
  printf '%s\n' "$values" > "$tmp/.rebrand/values.json"
  for ((i = 1; i <= passes; i++)); do
    git -C "$tmp" add -A
    if ! out="$(cd "$tmp" && node "$rebrand" --baseline-identity "$identity" --values .rebrand/values.json --allow-dirty 2>&1)"; then
      echo "   ✕  $name: rebrand pass $i failed:" >&2
      printf '%s\n' "$out" | sed 's/^/        /' >&2
      fail=1
      rm -rf "$tmp"
      return
    fi
  done
  got="$(cat "$tmp/$file")"
  rm -rf "$tmp"
  if [ "$got" = "$want" ]; then
    echo "   ok  $name"
  else
    echo "   ✕  $name:" >&2
    echo "        got:  $got" >&2
    echo "        want: $want" >&2
    fail=1
  fi
}

acme='{"reponame":"acme-notes","productname":"Acme Notes","productdomain":"acme.dev","githuborg":"acme-inc","subdomain":"acme","orunWorkspace":"ws_79BDXAZQ"}'

echo "── rebrand: the site's own identity"
check "the source link names the product's owner and repository" \
  "$acme" apps/web/site.js \
  'export const SOURCE_URL = "https://github.com/sourceplane/docusaurus"' \
  'export const SOURCE_URL = "https://github.com/acme-inc/acme-notes"'
check "the site-name seam takes the product's name" \
  "$acme" apps/web/site.js 'export const SITE_NAME = "My Site"' \
  'export const SITE_NAME = "Acme Notes"'
check "…and stays a valid string for a name with an apostrophe and an ampersand" \
  '{"reponame":"sams-docs","productname":"Sam'"'"'s Docs & Guides","productdomain":"sam.dev"}' \
  apps/web/site.js 'export const SITE_NAME = "My Site"' \
  'export const SITE_NAME = "Sam'"'"'s Docs & Guides"'
check "the edit links are built on the source link, so they follow it" \
  "$acme" apps/web/docusaurus.config.js 'const EDIT_URL = `${SOURCE_URL}/tree/main/apps/web/`;' \
  'const EDIT_URL = `${SOURCE_URL}/tree/main/apps/web/`;'
check "the display name elsewhere is content, and is left alone" \
  "$acme" apps/web/content/docs/intro.md 'Welcome to My Site.' \
  'Welcome to My Site.'

echo "── rebrand: the framework's name is the slug, and is not ours"
check "its packages are not renamed" \
  "$acme" apps/web/src/pages/index.js "import useDocusaurusContext from '@docusaurus/useDocusaurusContext';" \
  "import useDocusaurusContext from '@docusaurus/useDocusaurusContext';"
check "…its client modules either, whatever their case" \
  "$acme" apps/web/src/pages/index.js "import Link from '@docusaurus/Link'; import Layout from '@theme/Layout';" \
  "import Link from '@docusaurus/Link'; import Layout from '@theme/Layout';"
check "its CLI is not renamed, the package script that runs it either" \
  "$acme" apps/web/package.json '    "docusaurus": "docusaurus", "build": "docusaurus build", "start": "docusaurus start --port 3000",' \
  '    "docusaurus": "docusaurus", "build": "docusaurus build", "start": "docusaurus start --port 3000",'
check "its config file, generated directory and CSS variables are not renamed" \
  "$acme" apps/web/README.md 'docusaurus.config.js reads site.js; .docusaurus/ is generated; --docusaurus-highlighted-code-line-bg is its CSS' \
  'docusaurus.config.js reads site.js; .docusaurus/ is generated; --docusaurus-highlighted-code-line-bg is its CSS'
check "its homes and the template's community links are not renamed" \
  "$acme" apps/web/README.md 'https://docusaurus.io/docs https://github.com/facebook/docusaurus https://twitter.com/docusaurus' \
  'https://docusaurus.io/docs https://github.com/facebook/docusaurus https://twitter.com/docusaurus'
check "the example the site was taken from is credited as it is" \
  "$acme" README.md '[vercel/examples](https://github.com/vercel/examples), `framework-boilerplates/docusaurus-2`' \
  '[vercel/examples](https://github.com/vercel/examples), `framework-boilerplates/docusaurus-2`'
check "the template's writing names the framework, in either case" \
  "$acme" apps/web/content/blog/2019-05-28-first-blog-post.md 'tags: [hola, docusaurus] — Docusaurus, ![banner](./docusaurus-plushie-banner.jpeg), npm run docusaurus docs:version 1.1' \
  'tags: [hola, docusaurus] — Docusaurus, ![banner](./docusaurus-plushie-banner.jpeg), npm run docusaurus docs:version 1.1'
check "a bare slug in code is the baseline's own, and is renamed" \
  "$acme" apps/web/src/repo.js 'export const REPO = "docusaurus";' \
  'export const REPO = "acme-notes";'

check "the worker name is re-prefixed, the environment suffix kept" \
  "$acme" apps/web/component.yaml 'workerName: docusaurus-web' \
  'workerName: acme-notes-web'
check "an environment URL: worker name and subdomain" \
  "$acme" intent.yaml \
  '    url: https://docusaurus-web-stage.your-workers-subdomain.workers.dev' \
  '    url: https://acme-notes-web-stage.acme.workers.dev'
check "the placeholder domain is the product's domain, not a renamed slug" \
  "$acme" intent.yaml '      BASE_DOMAIN: docusaurus.example.com' \
  '      BASE_DOMAIN: acme.dev'
check "no domain given: the reserved placeholder, for an owner to replace later" \
  '{"reponame":"acme-notes","productname":"Acme Notes","githuborg":"acme-inc","subdomain":"acme"}' \
  intent.yaml '      BASE_DOMAIN: docusaurus.example.com' \
  '      BASE_DOMAIN: acme-notes.example.com'
check "an empty domain is no domain" \
  '{"reponame":"acme-notes","productname":"Acme Notes","productdomain":""}' \
  intent.yaml '      BASE_DOMAIN: docusaurus.example.com' \
  '      BASE_DOMAIN: acme-notes.example.com'
check "the repo slug" \
  "$acme" package.json '  "name": "docusaurus",' \
  '  "name": "acme-notes",'
check "a secret ref names the product's workspace and project" \
  "$acme" apps/web/component.yaml 'T: secret://ws_KWQ45Z6M/docusaurus/stage/CLOUDFLARE_API_TOKEN' \
  'T: secret://ws_79BDXAZQ/acme-notes/stage/CLOUDFLARE_API_TOKEN'
check "org-owned identity is not renamed" \
  "$acme" intent.yaml 'apiVersion: sourceplane.io/v1 # mail ops@sourceplane.ai' \
  'apiVersion: sourceplane.io/v1 # mail ops@sourceplane.ai'
check "without githuborg the source link keeps the baseline's owner" \
  '{"reponame":"acme-notes","productname":"Acme Notes","productdomain":"acme.dev"}' \
  apps/web/site.js 'const SOURCE_URL = "https://github.com/sourceplane/docusaurus"' \
  'const SOURCE_URL = "https://github.com/sourceplane/acme-notes"'

echo "── rebrand: a written value is not rewritten, in any later pass"
contains='{"reponame":"docusaurus-2","productname":"My Site 2","productdomain":"docusaurus.example.com.au","githuborg":"sourceplane","subdomain":"your-workers-subdomain-2"}'
check "a repo slug containing the baseline's slug survives three passes" \
  "$contains" package.json '  "name": "docusaurus",' \
  '  "name": "docusaurus-2",' 3
check "a worker name built on it survives three passes" \
  "$contains" apps/web/component.yaml 'workerName: docusaurus-web' \
  'workerName: docusaurus-2-web' 3
check "a domain containing the baseline's domain survives three passes" \
  "$contains" intent.yaml 'BASE_DOMAIN: docusaurus.example.com' \
  'BASE_DOMAIN: docusaurus.example.com.au' 3
check "a subdomain containing the placeholder survives three passes" \
  "$contains" apps/web/component.yaml 'workersDevSubdomain: your-workers-subdomain' \
  'workersDevSubdomain: your-workers-subdomain-2' 3
check "a site name containing the baseline's name survives three passes" \
  "$contains" apps/web/site.js 'export const SITE_NAME = "My Site"' \
  'export const SITE_NAME = "My Site 2"' 3

# --verify runs in every phase. Without the product's values it cannot tell
# the product's own identity from a leftover; with them it can. A real
# leftover must fail it either way.
verify() { # NAME VALUES FILE CONTENT WANT(pass|fail) [--values]
  local name="$1" values="$2" file="$3" content="$4" want="$5" withvalues="${6:-}" tmp got
  tmp="$(mktemp -d)"
  git -C "$tmp" init -q
  mkdir -p "$tmp/$(dirname "$file")" "$tmp/.rebrand"
  printf '%s\n' "$content" > "$tmp/$file"
  printf '%s\n' "$values" > "$tmp/.rebrand/values.json"
  git -C "$tmp" add -A
  if (cd "$tmp" && node "$rebrand" --baseline-identity "$identity" --verify ${withvalues:+--values .rebrand/values.json} >/dev/null 2>&1); then got=pass; else got=fail; fi
  rm -rf "$tmp"
  if [ "$got" = "$want" ]; then echo "   ok  $name"; else echo "   ✕  $name: --verify ${got}ed, want $want" >&2; fail=1; fi
}
echo "── rebrand --verify: the product's own identity is not residue"
verify "given the values, a slug containing the baseline's passes" \
  "$contains" package.json '"name": "docusaurus-2"' pass --values
verify "without them it cannot know, and fails" \
  "$contains" package.json '"name": "docusaurus-2"' fail
verify "given the values, a real leftover still fails" \
  "$acme" package.json '"name": "docusaurus"' fail --values
verify "a leftover worker name fails" \
  "$acme" apps/web/component.yaml 'workerName: docusaurus-web' fail --values
verify "a leftover code identifier fails (no rule renames it — so nothing may spell it)" \
  "$acme" apps/web/app/x.ts 'export class DocusaurusBaseline {}' fail --values
verify "a clean product passes" \
  "$acme" package.json '"name": "acme-notes"' pass --values
verify "the framework's packages, CLI, config file, CSS variables and homes are not residue" \
  "$acme" apps/web/README.md '@docusaurus/core, docusaurus build, docusaurus.config.js, .docusaurus/, --docusaurus-x, https://docusaurus.io' pass --values
verify "…nor the framework's name in the template's writing" \
  "$acme" apps/web/content/docs/intro.md 'Let us discover Docusaurus; npm run docusaurus; docusaurus-plushie-banner.jpeg' pass --values
verify "…but a bare slug in code is" \
  "$acme" apps/web/src/x.js 'const where = "docusaurus";' fail --values
verify "…and so is a plugin-looking name the framework does not have" \
  "$acme" apps/web/README.md 'docusaurus-web-extras' fail --values
verify "…and an env-var prefix, even in the template's writing" \
  "$acme" apps/web/content/docs/intro.md 'Set DOCUSAURUS_TOKEN first.' fail --values

echo "── rebrand: a residue it cannot rename fails the rebrand itself"
tmp="$(mktemp -d)"; git -C "$tmp" init -q; mkdir -p "$tmp/.rebrand" "$tmp/apps/web"
printf '%s\n' "$acme" > "$tmp/.rebrand/values.json"
printf 'const x = "DOCUSAURUS_TOKEN"\n' > "$tmp/apps/web/x.ts"
git -C "$tmp" add -A
if (cd "$tmp" && node "$rebrand" --baseline-identity "$identity" --values .rebrand/values.json --allow-dirty >/dev/null 2>&1); then
  echo "   ✕  an unrenamable env-var prefix passed the rebrand" >&2; fail=1
else
  echo "   ok  an unrenamable env-var prefix fails the rebrand, naming the file"
fi
rm -rf "$tmp"

[ "$fail" -eq 0 ] || exit 1
echo "rebrand.test.sh: ok"
