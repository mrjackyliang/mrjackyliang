import {
  describe,
  expect,
  it,
} from 'vitest';

import { Runner } from '../../src/lib/site.js';

/**
 * Site - Base Path Links.
 *
 * Confirms links keep the base path the site is served under, for a root
 * base and for a project site base, with or without a trailing slash.
 *
 * @since 1.0.0
 */
describe('Base path links', () => {
  it('leaves paths unchanged under a root base', () => {
    expect(Runner.withBase('/', '/')).toBe('/');

    expect(Runner.withBase('/scripts/', '/')).toBe('/scripts/');

    return;
  });

  it('prefixes paths with a project site base', () => {
    expect(Runner.withBase('/', '/mrjackyliang/')).toBe('/mrjackyliang/');

    expect(Runner.withBase('/scripts/', '/mrjackyliang')).toBe('/mrjackyliang/scripts/');

    expect(Runner.withBase('favicon.svg', '/mrjackyliang/')).toBe('/mrjackyliang/favicon.svg');

    return;
  });

  it('builds absolute URLs on the site origin', () => {
    expect(Runner.absoluteUrl('/thumbnails/home.png', 'https://mrjackyliang.github.io', '/mrjackyliang/')).toBe('https://mrjackyliang.github.io/mrjackyliang/thumbnails/home.png');

    return;
  });

  return;
});

/**
 * Site - Identity.
 *
 * Confirms the site name and copyright line come from "nova.config.json".
 *
 * @since 1.0.0
 */
describe('Identity', () => {
  it('reads the name and a copyright line starting in 2014', () => {
    expect(Runner.getIdentity()['title']).toBe('Jacky Liang');

    expect(Runner.getIdentity()['copyright']).toContain('2014-');

    return;
  });

  it('serves a manifest named after the project', async () => {
    expect(await Runner.serveManifest().text()).toContain('"name": "Jacky Liang"');

    return;
  });

  return;
});
