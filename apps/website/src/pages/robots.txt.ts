import { Runner } from '../lib/site.js';

/**
 * Pages - Robots - Serve Robots.
 *
 * Serves "robots.txt", which allows every crawler and points at the sitemap
 * index under the site's base path.
 *
 * @since 1.0.0
 */
const serveRobots = Runner['serveRobots'];

export { serveRobots as GET };
