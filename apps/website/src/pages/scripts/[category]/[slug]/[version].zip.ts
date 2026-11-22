import { Runner } from '../../../../lib/routes.js';

/**
 * Pages - Scripts - Category - Slug - Version - Get Static Paths.
 *
 * Lists "/scripts/<category>/<slug>/<version>.zip" for every script version,
 * plus "latest.zip", which packs the newest version at build time.
 *
 * @since 1.0.0
 */
export const getStaticPaths = Runner['getArchivePaths'];

/**
 * Pages - Scripts - Category - Slug - Version - Serve Archive.
 *
 * Serves the ZIP archive of one script version. Static builds write it to
 * the matching ".zip" path, so GitHub Pages serves it as a plain download.
 *
 * @since 1.0.0
 */
const serveArchive = Runner['serveArchive'];

export { serveArchive as GET };
