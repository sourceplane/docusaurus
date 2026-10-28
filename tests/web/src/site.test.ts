import { describe, expect, it } from "vitest";
import * as fs from "node:fs";
import * as path from "node:path";

const appDir = path.resolve(__dirname, "../../../apps/web");

type NavItem = { label?: string; href?: string; to?: string; type?: string };
type Config = {
  title: string;
  url: string;
  baseUrl: string;
  presets: [string, { docs: { path: string; editUrl: string }; blog: { path: string; editUrl: string } }][];
  themeConfig: {
    navbar: { title: string; logo: { alt: string }; items: NavItem[] };
    footer: { copyright: string; links: { items: NavItem[] }[] };
  };
};

async function config(): Promise<Config> {
  return (await import("@/docusaurus.config.js")).default as Config;
}

describe("site identity (apps/web/site.js)", () => {
  it("names the site and links its source repository", async () => {
    const { SITE_NAME, SOURCE_URL } = await import("@/site.js");
    expect(SITE_NAME.trim()).not.toBe("");
    expect(SOURCE_URL).toMatch(/^https:\/\/github\.com\/[A-Za-z0-9-]+\/[a-z0-9-]+$/);
  });

  it("is a literal the rename seam can find", () => {
    const site = fs.readFileSync(path.join(appDir, "site.js"), "utf8");
    expect(site).toMatch(/^export const SITE_NAME = "[^"]+";$/m);
  });

  it("is the one place the config takes its name and links from", async () => {
    const { SITE_NAME, SOURCE_URL } = await import("@/site.js");
    const c = await config();
    expect(c.title).toBe(SITE_NAME);
    expect(c.themeConfig.navbar.title).toBe(SITE_NAME);
    expect(c.themeConfig.navbar.logo.alt).toBe(`${SITE_NAME} Logo`);
    expect(c.themeConfig.footer.copyright).toContain(`${SITE_NAME}. Built with Docusaurus.`);
    const github = [...c.themeConfig.navbar.items, ...c.themeConfig.footer.links.flatMap((l) => l.items)].filter(
      (i) => i.label === "GitHub",
    );
    expect(github.map((i) => i.href)).toEqual([SOURCE_URL, SOURCE_URL]);
    // Nothing else in the config spells a GitHub repository.
    const source = fs.readFileSync(path.join(appDir, "docusaurus.config.js"), "utf8");
    expect(source).not.toMatch(/https:\/\/github\.com\//);
  });

  it("points 'Edit this page' at the content in that repository", async () => {
    const { SOURCE_URL } = await import("@/site.js");
    const [[preset, options]] = (await config()).presets as [Config["presets"][number]];
    expect(preset).toBe("classic");
    expect(options.docs.editUrl).toBe(`${SOURCE_URL}/tree/main/apps/web/`);
    expect(options.blog.editUrl).toBe(`${SOURCE_URL}/tree/main/apps/web/`);
  });

  it("builds for the origin the deploy names, and for localhost without one", async () => {
    const source = fs.readFileSync(path.join(appDir, "docusaurus.config.js"), "utf8");
    expect(source).toContain("process.env.PUBLIC_SITE_URL || 'http://localhost:3000'");
    const c = await config();
    expect(c.url).toBe(process.env.PUBLIC_SITE_URL || "http://localhost:3000");
    expect(c.baseUrl).toBe("/");
  });
});

describe("the Worker and its assets (apps/web/wrangler.jsonc)", () => {
  const wrangler = fs.readFileSync(path.join(appDir, "wrangler.jsonc"), "utf8");

  it("serves the static build behind the Worker, with the site's own 404 page", () => {
    expect(wrangler).toContain('"main": "./worker/index.ts"');
    expect(wrangler).toContain('"directory": "./build"');
    expect(wrangler).toContain('"binding": "ASSETS"');
    expect(wrangler).toContain('"not_found_handling": "404-page"');
  });

  it("answers the links Docusaurus renders (no trailing slash) without a redirect", () => {
    expect(wrangler).toContain('"html_handling": "drop-trailing-slash"');
  });
});
