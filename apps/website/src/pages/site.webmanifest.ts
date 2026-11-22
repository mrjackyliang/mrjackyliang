import { Runner } from '../lib/site.js';

/**
 * Pages - Site - Serve Manifest.
 *
 * Serves the web app manifest, with the name from "nova.config.json" and icon
 * and start paths under the site's base path.
 *
 * @since 1.0.0
 */
const serveManifest = Runner['serveManifest'];

export { serveManifest as GET };
