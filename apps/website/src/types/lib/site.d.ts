import type { Toolkit_NovaIdentity_Runner_ForDocs_Returns } from '@cbnventures/nova/types/toolkit/nova-identity.d.ts';
import type { APIContext } from 'astro';

/**
 * Lib - Site - Identity.
 *
 * @since 1.0.0
 */
export type Lib_Site_Runner_Identity = Toolkit_NovaIdentity_Runner_ForDocs_Returns;

export type Lib_Site_Runner_IdentityCache = Lib_Site_Runner_Identity | undefined;

/**
 * Lib - Site - Absolute Url.
 *
 * @since 1.0.0
 */
export type Lib_Site_Runner_AbsoluteUrl_Path = string;

export type Lib_Site_Runner_AbsoluteUrl_Site = URL | string | undefined;

export type Lib_Site_Runner_AbsoluteUrl_Base = string;

export type Lib_Site_Runner_AbsoluteUrl_Returns = string;

/**
 * Lib - Site - Get Identity.
 *
 * @since 1.0.0
 */
export type Lib_Site_Runner_GetIdentity_Returns = Lib_Site_Runner_Identity;

/**
 * Lib - Site - Serve Manifest.
 *
 * @since 1.0.0
 */
export type Lib_Site_Runner_ServeManifest_Returns = Response;

export type Lib_Site_Runner_ServeManifest_Identity = Lib_Site_Runner_Identity;

export type Lib_Site_Runner_ServeManifest_Manifest_Icon = {
  src: string;
  sizes: string;
  type: string;
};

export type Lib_Site_Runner_ServeManifest_Manifest = {
  name: string;
  short_name: string;
  description: string;
  icons: Lib_Site_Runner_ServeManifest_Manifest_Icon[];
  theme_color: string;
  background_color: string;
  start_url: string;
  scope: string;
  display: string;
};

/**
 * Lib - Site - Serve Robots.
 *
 * @since 1.0.0
 */
export type Lib_Site_Runner_ServeRobots_Context = APIContext;

export type Lib_Site_Runner_ServeRobots_Returns = Response;

export type Lib_Site_Runner_ServeRobots_SitemapUrl = string;

/**
 * Lib - Site - With Base.
 *
 * @since 1.0.0
 */
export type Lib_Site_Runner_WithBase_Path = string;

export type Lib_Site_Runner_WithBase_Base = string;

export type Lib_Site_Runner_WithBase_Returns = string;

export type Lib_Site_Runner_WithBase_Prefix = string;

export type Lib_Site_Runner_WithBase_Suffix = string;
