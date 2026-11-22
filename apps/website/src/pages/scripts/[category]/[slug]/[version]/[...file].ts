import { Runner } from '../../../../../lib/routes.js';

/**
 * Pages - Scripts - Category - Slug - Version - Get Static Paths.
 *
 * Lists "/scripts/<category>/<slug>/<version>/<file>" for every script file,
 * including the "latest" alias that copies the newest version at build time.
 *
 * @since 1.0.0
 */
export const getStaticPaths = Runner['getFilePaths'];

/**
 * Pages - Scripts - Category - Slug - Version - Serve File.
 *
 * Serves one script file as a plain download. Static builds write the bytes
 * to the matching path, so GitHub Pages serves them without a server.
 *
 * @since 1.0.0
 */
const serveFile = Runner['serveFile'];

export { serveFile as GET };
