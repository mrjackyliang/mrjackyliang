import NovaIdentity from '@cbnventures/nova/toolkit/nova-identity';

import type {
  Lib_Site_Runner_AbsoluteUrl_Base,
  Lib_Site_Runner_AbsoluteUrl_Path,
  Lib_Site_Runner_AbsoluteUrl_Returns,
  Lib_Site_Runner_AbsoluteUrl_Site,
  Lib_Site_Runner_GetIdentity_Returns,
  Lib_Site_Runner_IdentityCache,
  Lib_Site_Runner_ServeManifest_Identity,
  Lib_Site_Runner_ServeManifest_Manifest,
  Lib_Site_Runner_ServeManifest_Returns,
  Lib_Site_Runner_ServeRobots_Context,
  Lib_Site_Runner_ServeRobots_Returns,
  Lib_Site_Runner_ServeRobots_SitemapUrl,
  Lib_Site_Runner_WithBase_Base,
  Lib_Site_Runner_WithBase_Path,
  Lib_Site_Runner_WithBase_Prefix,
  Lib_Site_Runner_WithBase_Returns,
  Lib_Site_Runner_WithBase_Suffix,
} from '../types/lib/site.d.ts';

/**
 * Lib - Site.
 *
 * Reads the site's name, links, and copyright from "nova.config.json" and
 * builds links that keep the base path the site is served under.
 *
 * @since 1.0.0
 */
export class Runner {
  /**
   * Lib - Site - Identity.
   *
   * Holds the identity read once from the nearest "nova.config.json", so every
   * page shares the same name, links, and copyright line.
   *
   * @private
   *
   * @since 1.0.0
   */
  static #identity: Lib_Site_Runner_IdentityCache = undefined;

  /**
   * Lib - Site - Absolute URL.
   *
   * Turns a site path into a full URL on the site's origin, keeping the base
   * path, for canonical links, social cards, and structured data.
   *
   * @param {Lib_Site_Runner_AbsoluteUrl_Path} path - Path.
   * @param {Lib_Site_Runner_AbsoluteUrl_Site} site - Site.
   * @param {Lib_Site_Runner_AbsoluteUrl_Base} base - Base.
   *
   * @returns {Lib_Site_Runner_AbsoluteUrl_Returns}
   *
   * @since 1.0.0
   */
  public static absoluteUrl(path: Lib_Site_Runner_AbsoluteUrl_Path, site: Lib_Site_Runner_AbsoluteUrl_Site, base: Lib_Site_Runner_AbsoluteUrl_Base = import.meta.env.BASE_URL): Lib_Site_Runner_AbsoluteUrl_Returns {
    return new URL(Runner.withBase(path, base), site).href;
  }

  /**
   * Lib - Site - Get Identity.
   *
   * Returns the project identity from "nova.config.json" through Nova's
   * identity reader, loading it on the first call.
   *
   * @returns {Lib_Site_Runner_GetIdentity_Returns}
   *
   * @since 1.0.0
   */
  public static getIdentity(): Lib_Site_Runner_GetIdentity_Returns {
    if (Runner.#identity === undefined) {
      Runner.#identity = new NovaIdentity().forDocs();
    }

    return Runner.#identity;
  }

  /**
   * Lib - Site - Serve Manifest.
   *
   * Serves "site.webmanifest" with the site name from "nova.config.json" and
   * icon and start paths that keep the base path.
   *
   * @returns {Lib_Site_Runner_ServeManifest_Returns}
   *
   * @since 1.0.0
   */
  public static serveManifest(): Lib_Site_Runner_ServeManifest_Returns {
    const identity: Lib_Site_Runner_ServeManifest_Identity = Runner.getIdentity();
    const manifest: Lib_Site_Runner_ServeManifest_Manifest = {
      name: identity['title'] ?? '',
      short_name: identity['title'] ?? '',
      description: identity['metaDescription'] ?? '',
      icons: [
        {
          src: Runner.withBase('/web-app-manifest-192x192.png'),
          sizes: '192x192',
          type: 'image/png',
        },
        {
          src: Runner.withBase('/web-app-manifest-512x512.png'),
          sizes: '512x512',
          type: 'image/png',
        },
      ],
      theme_color: '#07090a',
      background_color: '#07090a',
      start_url: Runner.withBase('/'),
      scope: Runner.withBase('/'),
      display: 'standalone',
    };

    return new Response(`${JSON.stringify(manifest, null, 2)}\n`, {
      headers: {
        'Content-Type': 'application/manifest+json',
      },
    });
  }

  /**
   * Lib - Site - Serve Robots.
   *
   * Serves "robots.txt", allowing every crawler and pointing at the sitemap
   * index under the base path.
   *
   * @param {Lib_Site_Runner_ServeRobots_Context} context - Context.
   *
   * @returns {Lib_Site_Runner_ServeRobots_Returns}
   *
   * @since 1.0.0
   */
  public static serveRobots(context: Lib_Site_Runner_ServeRobots_Context): Lib_Site_Runner_ServeRobots_Returns {
    const sitemapUrl: Lib_Site_Runner_ServeRobots_SitemapUrl = Runner.absoluteUrl('/sitemap-index.xml', context['site']);

    return new Response([
      'User-agent: *',
      'Allow: /',
      '',
      `Sitemap: ${sitemapUrl}`,
      '',
    ].join('\n'), {
      headers: {
        'Content-Type': 'text/plain; charset=utf-8',
      },
    });
  }

  /**
   * Lib - Site - With Base.
   *
   * Puts the base path in front of a site path, such as "/scripts/" becoming
   * "/mrjackyliang/scripts/". A root base leaves the path unchanged.
   *
   * @param {Lib_Site_Runner_WithBase_Path} path - Path.
   * @param {Lib_Site_Runner_WithBase_Base} base - Base.
   *
   * @returns {Lib_Site_Runner_WithBase_Returns}
   *
   * @since 1.0.0
   */
  public static withBase(path: Lib_Site_Runner_WithBase_Path, base: Lib_Site_Runner_WithBase_Base = import.meta.env.BASE_URL): Lib_Site_Runner_WithBase_Returns {
    const prefix: Lib_Site_Runner_WithBase_Prefix = (base.endsWith('/') === true) ? base.slice(0, -1) : base;
    const suffix: Lib_Site_Runner_WithBase_Suffix = (path.startsWith('/') === true) ? path : `/${path}`;

    return `${prefix}${suffix}`;
  }
}
