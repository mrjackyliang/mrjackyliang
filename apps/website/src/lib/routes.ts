import { getCollection } from 'astro:content';

import { Runner as Scripts } from './scripts.js';

import type {
  Lib_Routes_Runner_GetArchivePaths_Returns,
  Lib_Routes_Runner_GetArchivePaths_Targets,
  Lib_Routes_Runner_GetFilePaths_Paths,
  Lib_Routes_Runner_GetFilePaths_Returns,
  Lib_Routes_Runner_GetFilePaths_Targets,
  Lib_Routes_Runner_GetTargets_Entries,
  Lib_Routes_Runner_GetTargets_EntryCategory,
  Lib_Routes_Runner_GetTargets_EntryIdParts,
  Lib_Routes_Runner_GetTargets_EntryLatest,
  Lib_Routes_Runner_GetTargets_EntrySlug,
  Lib_Routes_Runner_GetTargets_EntryVersions,
  Lib_Routes_Runner_GetTargets_Returns,
  Lib_Routes_Runner_GetTargets_Targets,
  Lib_Routes_Runner_ServeArchive_Archive,
  Lib_Routes_Runner_ServeArchive_Context,
  Lib_Routes_Runner_ServeArchive_Returns,
  Lib_Routes_Runner_ServeFile_Contents,
  Lib_Routes_Runner_ServeFile_Context,
  Lib_Routes_Runner_ServeFile_File,
  Lib_Routes_Runner_ServeFile_Returns,
} from '../types/lib/routes.d.ts';

/**
 * Lib - Routes.
 *
 * Builds the static download routes for every script version and "latest".
 * The endpoint files under "src/pages/scripts/" delegate to these helpers.
 *
 * @since 1.0.0
 */
export class Runner {
  /**
   * Lib - Routes - Get Archive Paths.
   *
   * Lists one ZIP route per script version, plus one for the latest version.
   * Each route carries the real version so "latest" packs the newest files.
   *
   * @returns {Lib_Routes_Runner_GetArchivePaths_Returns}
   *
   * @since 1.0.0
   */
  public static async getArchivePaths(): Lib_Routes_Runner_GetArchivePaths_Returns {
    const targets: Lib_Routes_Runner_GetArchivePaths_Targets = await Runner.getTargets();

    return targets.map((target) => ({
      params: {
        category: target['category'],
        slug: target['slug'],
        version: target['label'],
      },
      props: target,
    }));
  }

  /**
   * Lib - Routes - Get File Paths.
   *
   * Lists one plain download route per file, for every version and "latest".
   * Multi-file scripts get a route for each file in their nested folders.
   *
   * @returns {Lib_Routes_Runner_GetFilePaths_Returns}
   *
   * @since 1.0.0
   */
  public static async getFilePaths(): Lib_Routes_Runner_GetFilePaths_Returns {
    const targets: Lib_Routes_Runner_GetFilePaths_Targets = await Runner.getTargets();
    const paths: Lib_Routes_Runner_GetFilePaths_Paths = [];

    for (const target of targets) {
      for (const file of Scripts.listFiles(target)) {
        paths.push({
          params: {
            category: target['category'],
            slug: target['slug'],
            version: target['label'],
            file,
          },
          props: {
            ...target,
            file,
          },
        });
      }
    }

    return paths;
  }

  /**
   * Lib - Routes - Serve Archive.
   *
   * Responds with the ZIP archive of the version named by the route props.
   * Static builds write the response body to the matching ".zip" file.
   *
   * @param {Lib_Routes_Runner_ServeArchive_Context} context - Context.
   *
   * @returns {Lib_Routes_Runner_ServeArchive_Returns}
   *
   * @since 1.0.0
   */
  public static serveArchive(context: Lib_Routes_Runner_ServeArchive_Context): Lib_Routes_Runner_ServeArchive_Returns {
    const archive: Lib_Routes_Runner_ServeArchive_Archive = Scripts.createArchive({
      category: String(context.props['category']),
      slug: String(context.props['slug']),
      version: String(context.props['version']),
      date: String(context.props['date']),
    });

    return new Response(new Uint8Array(archive), {
      headers: {
        'Content-Type': 'application/zip',
      },
    });
  }

  /**
   * Lib - Routes - Serve File.
   *
   * Responds with the raw bytes of one script file named by the route props.
   * Static builds write the response body to the matching file path.
   *
   * @param {Lib_Routes_Runner_ServeFile_Context} context - Context.
   *
   * @returns {Lib_Routes_Runner_ServeFile_Returns}
   *
   * @since 1.0.0
   */
  public static serveFile(context: Lib_Routes_Runner_ServeFile_Context): Lib_Routes_Runner_ServeFile_Returns {
    const file: Lib_Routes_Runner_ServeFile_File = String(context.props['file']);
    const contents: Lib_Routes_Runner_ServeFile_Contents = Scripts.readFile({
      category: String(context.props['category']),
      slug: String(context.props['slug']),
      version: String(context.props['version']),
    }, file);

    return new Response(new Uint8Array(contents), {
      headers: {
        'Content-Type': 'application/octet-stream',
      },
    });
  }

  /**
   * Lib - Routes - Get Targets.
   *
   * Expands every script into its versions plus a "latest" alias target.
   * The alias points at the highest version, so it moves on each release.
   *
   * @private
   *
   * @returns {Lib_Routes_Runner_GetTargets_Returns}
   *
   * @since 1.0.0
   */
  private static async getTargets(): Lib_Routes_Runner_GetTargets_Returns {
    const entries: Lib_Routes_Runner_GetTargets_Entries = await getCollection('scripts');
    const targets: Lib_Routes_Runner_GetTargets_Targets = [];

    for (const entry of entries) {
      const entryIdParts: Lib_Routes_Runner_GetTargets_EntryIdParts = entry['id'].split('/');
      const entryCategory: Lib_Routes_Runner_GetTargets_EntryCategory = entryIdParts[0] ?? '';
      const entrySlug: Lib_Routes_Runner_GetTargets_EntrySlug = entryIdParts[1] ?? '';
      const entryVersions: Lib_Routes_Runner_GetTargets_EntryVersions = entry['data']['versions'];
      const entryLatest: Lib_Routes_Runner_GetTargets_EntryLatest = Scripts.getLatestVersion(entryVersions);

      for (const entryVersion of entryVersions) {
        targets.push({
          category: entryCategory,
          slug: entrySlug,
          version: entryVersion['version'],
          date: entryVersion['date'],
          label: entryVersion['version'],
        });
      }

      if (entryLatest !== undefined) {
        targets.push({
          category: entryCategory,
          slug: entrySlug,
          version: entryLatest['version'],
          date: entryLatest['date'],
          label: 'latest',
        });
      }
    }

    return targets;
  }
}
