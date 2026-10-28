#!/usr/bin/env bash
# TIER 2 — the site a bootstrap produces builds, deploys (dry) and serves.
#
# placement.test.sh proves the tree a bootstrap ends with is the right tree.
# This proves it WORKS, by doing to it what its own pipelines will:
#
#   1. at the finished site, the landing's own checks — install with the
#      lockfile the site ships, render fixtures, typecheck, lint, test,
#      build. The bootstrap's own landings are checked in the box with
#      `orun validate` and `orun plan` alone (`checks: local`; their PR's CI
#      on an `orun/BASE-…` branch is `plan` alone, and the convergence on
#      main builds, deploys and smoke-tests the site), so THIS is where a
#      site those steps refuse is caught: before the tag, not after a build
#      has merged it. Every later pull request of the site runs ci.yml's
#      verify lanes;
#   2. the stage lane's own steps, rendered by `orun plan` in the site: on a
#      pull request (the verify profile) `verify-app-structure`, `build-app` —
#      the component's buildCommand (`docusaurus build` through turbo, for the
#      stage lane's own origin), the same step the deploy profile runs —
#      `verify-build-output` and `deploy-dry-run` (`wrangler deploy --dry-run
#      --name <reponame>-web-stage`). They run IN THE TREE THE RUNNER STAGES
#      for the job (testing/lib/stage-job.py), with the dependency layout the
#      pinned composition produces: if its install step is `scope: lane`, the
#      top-level node_modules is a symlink to the source checkout's; if not,
#      the job's own install step runs inside the staged tree. The staged build
#      must have written its OWN site — the source tree's build/ and
#      .docusaurus/ are removed before staging, as a CI checkout has none —
#      every docs page and blog post, for the stage origin;
#   3. serve the built Worker with `wrangler dev` and run the component's OWN
#      `smokeCommand` against it, verbatim — the check the real deploy ends
#      with — and then read every route the site promises: the titles, the
#      navbar and the footer carry the site's name, the GitHub and "Edit this
#      page" links point at the site's repository, every docs page and blog
#      post renders, canonical links, the sitemap and the feeds are on the
#      stage origin, links are answered without a redirect, and an unknown
#      path is the site's own 404 page with a 404.
#
# What it cannot do is the platform's half: create the repository, mint the
# brokered Cloudflare token, deploy for real and probe workers.dev. That is a
# bootstrap against a workspace (BOOTSTRAP.md); everything short of it is here.
#
# Needs: orun, node, pnpm, python3 (+PyYAML), git, curl, and the network for
# `pnpm install` (or a warm store). A few minutes: two installs and builds
# (the landing's checks over the site, and the stage lane's own in its staged
# tree).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/.." && pwd)"
# shellcheck source=lib/bootstrap.sh
source "$here/lib/bootstrap.sh"

for bin in orun node pnpm python3 git curl; do
  command -v "$bin" >/dev/null || { echo "e2e.test.sh needs $bin on PATH" >&2; exit 1; }
done

scratch="$(mktemp -d)"
dev_pid=""
# wrangler dev runs under pnpm, node and two workerd processes; a TERM to the
# first does not reach the rest, and waiting on it then never returns. So it is
# started as its own process group (setsid) and the whole group is stopped.
cleanup() {
  if [ -n "$dev_pid" ]; then
    kill -TERM -- "-$dev_pid" 2>/dev/null || true
    for _ in 1 2 3 4 5 6 7 8 9 10; do kill -0 -- "-$dev_pid" 2>/dev/null || break; sleep 0.5; done
    kill -KILL -- "-$dev_pid" 2>/dev/null || true
  fi
  rm -rf "$scratch"
}
trap cleanup EXIT
values="$here/fixtures/acme.json"
repo="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['reponame'])" "$values")"
export CI=1 WRANGLER_SEND_METRICS=false TURBO_TELEMETRY_DISABLED=1

# The landing's own checks, step for step, run here at once on the whole
# tree. A pull request in the site builds and dry-deploys it through ci.yml's
# lanes; the lint and the tests run here, and by hand before a push.
LANDING_CHECKS=(
  "pnpm install --frozen-lockfile"
  "pnpm run wire:fixture"
  "pnpm typecheck"
  "pnpm lint"
  "pnpm test"
  "pnpm build"
)
checks() { # DIR LOG
  local dir="$1" log="$2" cmd
  for cmd in "${LANDING_CHECKS[@]}"; do
    echo "   \$ $cmd" | tee -a "$log"
    if ! (cd "$dir" && bash -c "$cmd") >> "$log" 2>&1; then
      echo "FAIL: \`$cmd\` failed in $dir" >&2; tail -40 "$log" >&2; return 1
    fi
  done
}

echo "── the offline bootstrap (testing/lib/bootstrap.sh)"
tree="$scratch/$repo"
bootstrap_offline "$root" "$tree" "$values" "$scratch/logs" > "$scratch/bootstrap.log" 2>&1 || {
  echo "FAIL: the offline bootstrap stopped" >&2; tail -40 "$scratch/bootstrap.log" >&2; exit 1; }
echo "   2 phases placed and landed"

# ── 1. the finished site ───────────────────────────────────────────────────
echo "── the finished site: install, the fixture render, typecheck, lint, test, build"
checks "$tree" "$scratch/checks-site.log"

# ── 2. the deploy lane's steps, for stage ──────────────────────────────────
echo "── the stage lane: verify-app-structure, build-app, verify-build-output, deploy-dry-run"
# The 01-product landing over the repository's empty first commit: every file
# of the site changed, as on its pull request.
s00="$(git -C "$tree" rev-parse HEAD~2)"; s01="$(git -C "$tree" rev-parse HEAD~1)"
(cd "$tree" && orun plan --intent intent.yaml --trigger github-pull-request --changed \
   --base "$s00" --head "$s01" --env stage --output "$scratch/plan.json") > "$scratch/plan.log" 2>&1 \
  || { echo "FAIL: orun plan" >&2; tail -15 "$scratch/plan.log" >&2; exit 1; }
python3 - "$scratch/plan.json" "$scratch/steps" <<'PY'
import json, pathlib, sys
plan = json.load(open(sys.argv[1]))
out = pathlib.Path(sys.argv[2]); out.mkdir()
job = next(j for j in plan["jobs"] if j["component"] == "web" and j["environment"] == "stage")
for s in job["steps"]:
    if s["id"] in ("verify-app-structure", "build-app", "verify-build-output", "deploy-dry-run"):
        (out / f"{s['id']}.sh").write_text(s.get("run") or "")
    if s["id"] == "install-workspace-dependencies":
        (out / "install.sh").write_text(s.get("run") or "")
        (out / "install.wd").write_text(s.get("working-directory") or ".")
        (out / "install.scope").write_text(s.get("scope") or "job")
(out / "path").write_text(job.get("path") or "apps/web")
for k, v in (job.get("env") or {}).items():
    (out / "env").open("a").write(f"export {k}={json.dumps(v)}\n")
PY
# The job's private tree, staged as orun stages it. The source checkout
# carries no build output (a CI checkout has none, so the plain-tree build's is
# removed rather than copied in), and its dependencies are what the pinned
# composition says: a lane-scoped install ran once in the source tree (step 1
# ran the same command) and is linked in, or the job installs its own.
rm -rf "$tree/apps/web/build" "$tree/apps/web/.docusaurus" "$tree/apps/web/.wrangler"
work="$tree/.orun/runs/e2e/web.stage.verify-deploy/work"
[ -f "$scratch/steps/install.sh" ] || { echo "FAIL: the stage lane has no install step" >&2; exit 1; }
if [ "$(cat "$scratch/steps/install.scope")" = lane ]; then
  python3 "$here/lib/stage-job.py" "$tree" "$work" --shared-deps
  [ -L "$work/node_modules" ] || { echo "FAIL: the staged tree's node_modules is not the lane's symlink" >&2; exit 1; }
  echo "   staged: $(realpath --relative-to="$tree" "$work"); install scope: lane — node_modules → the source tree's"
else
  python3 "$here/lib/stage-job.py" "$tree" "$work"
  echo "   staged: $(realpath --relative-to="$tree" "$work"); install scope: job — installing inside it"
  echo "   ▸ install-workspace-dependencies"
  (cd "$work/$(cat "$scratch/steps/path")/$(cat "$scratch/steps/install.wd")" && bash -e "$scratch/steps/install.sh") \
    > "$scratch/install.log" 2>&1 || { echo "FAIL: the lane's install step" >&2; tail -30 "$scratch/install.log" >&2; exit 1; }
  [ -d "$work/node_modules" ] && [ ! -L "$work/node_modules" ] \
    || { echo "FAIL: the job's install did not land inside its own tree" >&2; exit 1; }
fi
for step in verify-app-structure build-app verify-build-output deploy-dry-run; do
  [ -f "$scratch/steps/$step.sh" ] || { echo "FAIL: the stage verify lane has no $step step" >&2; exit 1; }
  echo "   ▸ $step"
  # The runner's per-job environment: the job's env (intent environment
  # `env:`) and ORUN_ENVIRONMENT; the step runs in the component's directory.
  if ! (cd "$work/$(cat "$scratch/steps/path")" && \
        { [ -f "$scratch/steps/env" ] && source "$scratch/steps/env"; true; } && \
        export ORUN_ENVIRONMENT=stage && bash -e "$scratch/steps/$step.sh") > "$scratch/$step.log" 2>&1; then
    echo "FAIL: the deploy lane's $step step" >&2; tail -40 "$scratch/$step.log" >&2; exit 1
  fi
done
# What the staged build must have been: Docusaurus's, writing a site of its
# own (the source tree's was removed) with a page for every docs page and blog
# post, for the stage lane's origin.
grep -q 'Generated static files in "build"' "$scratch/build-app.log" \
  || { echo "FAIL: the staged build is not Docusaurus's" >&2; tail -20 "$scratch/build-app.log" >&2; exit 1; }
python3 - "$work/apps/web" "$values" <<'PY' || exit 1
import json, pathlib, sys
app, values = pathlib.Path(sys.argv[1]), json.load(open(sys.argv[2]))
origin = f"https://{values['reponame']}-web-stage.{values['subdomain']}.workers.dev"
build = app / "build"
docs = sorted(p.relative_to(app / "content/docs").with_suffix("").as_posix()
              for p in (app / "content/docs").rglob("*.md*"))
missing = [d for d in docs if not (build / "docs" / d / "index.html").is_file()]
if missing:
    sys.exit(f"FAIL: the staged build has no page for {missing}")
for f in ("index.html", "404.html", "sitemap.xml", "blog/rss.xml", "blog/atom.xml"):
    if not (build / f).is_file():
        sys.exit(f"FAIL: the staged build has no {f}")
sitemap = (build / "sitemap.xml").read_text()
if f"<loc>{origin}/docs/intro</loc>" not in sitemap:
    sys.exit(f"FAIL: the staged build's sitemap is not on {origin}")
print(f"   the staged build wrote its own site: {len(docs)} docs pages, the blog, its feeds and a sitemap on {origin}")
PY

# What the deploy would upload: the Worker bundled from its source entry, and
# the static build beside it as assets.
grep -q 'Total Upload' "$scratch/deploy-dry-run.log" || { echo "FAIL: the dry run listed no Worker upload" >&2; tail -20 "$scratch/deploy-dry-run.log" >&2; exit 1; }
grep -m1 'Total Upload' "$scratch/deploy-dry-run.log" | sed 's/^/   /'
cfg="$(python3 -c "import yaml,sys;print(yaml.safe_load(open(sys.argv[1]))['spec']['parameters']['wranglerConfig'])" "$tree/apps/web/component.yaml")"

# ── 3. serve it, and smoke it as the deploy does ───────────────────────────
echo "── wrangler dev over the built Worker ($cfg)"
port=$(python3 -c "import socket;s=socket.socket();s.bind(('127.0.0.1',0));print(s.getsockname()[1]);s.close()")
(cd "$work/apps/web" && exec setsid pnpm exec wrangler dev --config "$cfg" --ip 127.0.0.1 --port "$port" \
   --name "$repo-web-stage" --show-interactive-dev-session=false) > "$scratch/dev.log" 2>&1 < /dev/null &
dev_pid=$!
url="http://127.0.0.1:$port"
for _ in $(seq 1 90); do
  curl -s -o /dev/null "$url/" && break
  kill -0 "$dev_pid" 2>/dev/null || { echo "FAIL: wrangler dev exited" >&2; tail -30 "$scratch/dev.log" >&2; exit 1; }
  sleep 1
done
curl -s -o /dev/null "$url/" || { echo "FAIL: wrangler dev never answered" >&2; tail -30 "$scratch/dev.log" >&2; exit 1; }

echo "   ▸ the component's own smokeCommand, DEPLOYED_URL=$url"
smoke="$(python3 -c "import yaml,sys;print(yaml.safe_load(open(sys.argv[1]))['spec']['parameters']['smokeCommand'])" "$tree/apps/web/component.yaml")"
DEPLOYED_URL="$url" bash -c "$smoke" || { echo "FAIL: the deploy's smoke refused the site" >&2; exit 1; }

echo "   ▸ every route the site promises"
python3 - "$url" "$values" "$work/apps/web" <<'PY'
import html, json, pathlib, re, sys, urllib.error, urllib.parse, urllib.request
base, values, app = sys.argv[1], json.load(open(sys.argv[2])), pathlib.Path(sys.argv[3])
name, repo, org = values["productname"], values["reponame"], values["githuborg"]
source = f"https://github.com/{org}/{repo}"
# The origin the stage lane built for: its workers.dev URL (no SITE_URL set).
origin = f"https://{repo}-web-stage.{values['subdomain']}.workers.dev"
problems = []
def bad(m): problems.append(m)
class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *a, **k): return None
opener = urllib.request.build_opener(NoRedirect)
def get(path):
    try:
        with opener.open(urllib.parse.urljoin(base + "/", path), timeout=30) as r:
            return r.status, r.headers, r.read()
    except urllib.error.HTTPError as e:
        return e.code, e.headers, e.read()
def text(fragment):
    return html.unescape(re.sub(r"<[^>]+>", " ", fragment))
def title(page):
    m = re.search(r"<title[^>]*>(.*?)</title>", page, re.S)
    return html.unescape(m.group(1)) if m else None
def canonical(page):
    m = re.search(r'<link[^>]*rel="canonical"[^>]*href="([^"]+)"', page)
    return m and m.group(1)

# / — the template's home page, under the site's name.
status, headers, body = get("/")
page = body.decode()
if status != 200:
    bad(f"/ answered {status}")
if title(page) != f"Hello from {name} | {name}":
    bad(f"the home page's <title> is {title(page)!r}, not 'Hello from {name} | {name}'")
if "Docusaurus Tutorial - 5min" not in page or "Dinosaurs are cool" not in page:
    bad("the home page is not the template's (its tagline and its tutorial button)")
navbar = re.search(r'<nav[^>]*class="[^"]*navbar[^"]*".*?</nav>', page, re.S)
if not navbar or name not in text(navbar.group(0)):
    bad(f"the navbar does not say {name!r}")
if navbar and f'href="{source}"' not in navbar.group(0):
    bad(f"the navbar's GitHub link is not the site's repository {source}")
footer = re.search(r"<footer.*?</footer>", page, re.S)
if not footer or f"{name}. Built with Docusaurus." not in text(footer.group(0)):
    bad(f"the footer's copyright does not name {name!r}")
if canonical(page) != f"{origin}/":
    bad(f"the home page's canonical link is {canonical(page)!r}, not {origin}/")
for leftover in ("My Site", "docusaurus-web", "github.com/sourceplane/"):
    if leftover in html.unescape(page):
        bad(f"the home page still carries {leftover!r}")

# Every docs page, as the sidebar links it (no trailing slash, answered
# without a redirect), with an "Edit this page" link into the site's repo.
docs = sorted(p.relative_to(app / "content/docs").with_suffix("").as_posix()
              for p in (app / "content/docs").rglob("*.md*"))
for d in docs:
    s, h, b = get(f"/docs/{d}")
    p = b.decode()
    if s != 200:
        bad(f"/docs/{d} answered {s}")
        continue
    if not (title(p) or "").endswith(f" | {name}"):
        bad(f"/docs/{d} is titled {title(p)!r}, not '… | {name}'")
    src = next((app / "content/docs").glob(f"{d}.md*"))
    edit = f"{source}/tree/main/apps/web/content/docs/{d}{src.suffix}"
    if f'href="{edit}"' not in p:
        bad(f"/docs/{d} has no 'Edit this page' link to {edit}")
    if canonical(p) != f"{origin}/docs/{d}":
        bad(f"/docs/{d}'s canonical link is {canonical(p)!r}")
s, h, b = get("/docs/intro")
if "Docusaurus in less than 5 minutes" not in b.decode():
    bad("/docs/intro is not the template's tutorial intro")
for path in ("/docs/category/tutorial---basics", "/docs/category/tutorial---extras", "/markdown-page"):
    s, _, _ = get(path)
    if s != 200:
        bad(f"{path} answered {s}")

# The blog: the index, every post, tags, authors and the archive.
for path in ("/blog", "/blog/welcome", "/blog/mdx-blog-post", "/blog/long-blog-post", "/blog/first-blog-post",
             "/blog/tags", "/blog/tags/docusaurus", "/blog/archive", "/blog/authors"):
    s, h, b = get(path)
    if s != 200:
        bad(f"{path} answered {s}")
s, h, b = get("/blog")
if title(b.decode()) != f"Blog | {name}":
    bad(f"/blog is titled {title(b.decode())!r}")
s, h, b = get("/blog/welcome")
img = re.search(r'<img[^>]+src="(/assets/images/docusaurus-plushie-banner-[^"]+)"', b.decode())
if not img:
    bad("/blog/welcome does not show the template's banner image")
else:
    s, h, _ = get(img.group(1))
    if s != 200 or not (h.get("content-type") or "").startswith("image/"):
        bad(f"{img.group(1)} answered {s} {h.get('content-type')}")

# Feeds and the sitemap, on the stage origin.
s, h, b = get("/blog/rss.xml")
feed = b.decode()
if s != 200 or "<rss" not in feed or f"{origin}/blog/welcome" not in feed:
    bad(f"/blog/rss.xml answered {s} without the posts on {origin}")
channel = re.search(r"<channel>\s*<title>(.*?)</title>", feed, re.S)
if not channel or html.unescape(channel.group(1)) != f"{name} Blog":
    bad(f"/blog/rss.xml is titled {channel and html.unescape(channel.group(1))!r}, not '{name} Blog'")
s, h, b = get("/blog/atom.xml")
if s != 200 or "<feed" not in b.decode():
    bad(f"/blog/atom.xml answered {s}")
s, h, b = get("/sitemap.xml")
if s != 200 or f"<loc>{origin}/docs/intro</loc>" not in b.decode():
    bad(f"/sitemap.xml answered {s} without the docs on {origin}")

# A link with a trailing slash redirects to the one the site renders.
s, h, _ = get("/docs/intro/")
if s not in (301, 307, 308) or not (h.get("location") or "").endswith("/docs/intro"):
    bad(f"/docs/intro/ answered {s} → {h.get('location')!r}, not a redirect to /docs/intro")

# An unknown path: the site's own 404 page, with a 404.
s, h, b = get("/no-such-page")
if s != 404 or title(b.decode()) != f"Page Not Found | {name}":
    bad(f"/no-such-page answered {s} titled {title(b.decode())!r}")

if problems:
    for p in problems:
        print(f"  ✕ {p}", file=sys.stderr)
    sys.exit(1)
print(f"   /, {len(docs)} docs pages with their edit links, the blog and its posts, tags, authors and archive, "
      f"the feeds and the sitemap on the stage origin, slash redirects and the 404 — the site's own, named {name!r}")
PY

echo "e2e.test.sh: ok"
