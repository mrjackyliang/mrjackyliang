import { readFileSync } from 'node:fs';

import sitemap from '@astrojs/sitemap';
import NovaIdentity from '@cbnventures/nova/toolkit/nova-identity';
import { defineConfig } from 'astro/config';

/**
 * Astro - Homepage.
 *
 * Reads "urls.homepage" from the project's "nova.config.json", so the site
 * origin and base path follow the project identity.
 *
 * @since 1.0.0
 */
const homepage = JSON.parse(readFileSync(new URL('../../nova.config.json', import.meta.url), 'utf-8'))['urls']['homepage'];

/**
 * Astro - Config.
 *
 * Configures a static Astro application.
 * Keeps generated output in Nova's standard build directory.
 * Splits the homepage into the GitHub Pages origin and its base path.
 *
 * @since 0.0.0
 */
const config = defineConfig({
  site: NovaIdentity.docsUrl(homepage) ?? homepage,
  base: NovaIdentity.docsBaseUrl(homepage) ?? '/',
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
    routing: {
      prefixDefaultLocale: false,
    },
  },
  integrations: [sitemap({
    filter: (page) => new URL(page).pathname.endsWith('/404/') === false,
  })],
  outDir: './build',
  output: 'static',
});

export default config;
