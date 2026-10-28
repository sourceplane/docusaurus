// @ts-check
// Note: type annotations allow type checking and IDEs autocompletion

import {themes as prismThemes} from 'prism-react-renderer';
import {SITE_NAME, SOURCE_URL} from './site.js';

// The site's public origin: canonical links, the sitemap and the blog's
// feeds are absolute. Every deploy sets PUBLIC_SITE_URL to its environment's
// origin (apps/web/component.yaml's buildCommand); a local build without it
// is for localhost.
const SITE_URL = process.env.PUBLIC_SITE_URL || 'http://localhost:3000';

// "Edit this page" opens the page's source in this site's repository.
const EDIT_URL = `${SOURCE_URL}/tree/main/apps/web/`;

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: SITE_NAME,
  tagline: 'Dinosaurs are cool',
  url: SITE_URL,
  baseUrl: '/',
  onBrokenLinks: 'throw',
  markdown: {
    hooks: {
      onBrokenMarkdownLinks: 'warn',
    },
  },
  favicon: 'img/favicon.ico',

  // Even if you don't use internalization, you can use this field to set useful
  // metadata like html lang. For example, if your site is Chinese, you may want
  // to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          // The docs and the blog live under content/: apps/web/docs/ holds
          // this component's own catalog pages (overview, architecture,
          // runbook), which must not become pages of the site.
          path: 'content/docs',
          sidebarPath: './sidebars.js',
          editUrl: EDIT_URL,
        },
        blog: {
          path: 'content/blog',
          showReadingTime: true,
          editUrl: EDIT_URL,
        },
        theme: {
          customCss: './src/css/custom.css',
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      navbar: {
        title: SITE_NAME,
        logo: {
          alt: `${SITE_NAME} Logo`,
          src: 'img/logo.svg',
        },
        items: [
          {
            type: 'doc',
            docId: 'intro',
            position: 'left',
            label: 'Tutorial',
          },
          {to: '/blog', label: 'Blog', position: 'left'},
          {
            href: SOURCE_URL,
            label: 'GitHub',
            position: 'right',
          },
        ],
      },
      footer: {
        style: 'dark',
        links: [
          {
            title: 'Docs',
            items: [
              {
                label: 'Tutorial',
                to: '/docs/intro',
              },
            ],
          },
          {
            title: 'Community',
            items: [
              {
                label: 'Stack Overflow',
                href: 'https://stackoverflow.com/questions/tagged/docusaurus',
              },
              {
                label: 'Discord',
                href: 'https://discordapp.com/invite/docusaurus',
              },
              {
                label: 'Twitter',
                href: 'https://twitter.com/docusaurus',
              },
            ],
          },
          {
            title: 'More',
            items: [
              {
                label: 'Blog',
                to: '/blog',
              },
              {
                label: 'GitHub',
                href: SOURCE_URL,
              },
            ],
          },
        ],
        copyright: `Copyright © ${new Date().getFullYear()} ${SITE_NAME}. Built with Docusaurus.`,
      },
      prism: {
        theme: prismThemes.github,
        darkTheme: prismThemes.dracula,
      },
    }),
};

export default config;
