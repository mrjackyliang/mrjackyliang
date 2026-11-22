import { readdirSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { crc32, deflateRawSync } from 'node:zlib';

import { LIB_REGEX_SEMANTIC_VERSION } from './regex.js';

import type {
  Lib_Scripts_Runner_CompareVersions_Difference,
  Lib_Scripts_Runner_CompareVersions_Left,
  Lib_Scripts_Runner_CompareVersions_LeftMatch,
  Lib_Scripts_Runner_CompareVersions_Returns,
  Lib_Scripts_Runner_CompareVersions_Right,
  Lib_Scripts_Runner_CompareVersions_RightMatch,
  Lib_Scripts_Runner_CreateArchive_ArchiveDate,
  Lib_Scripts_Runner_CreateArchive_CentralHeader,
  Lib_Scripts_Runner_CreateArchive_CentralHeaders,
  Lib_Scripts_Runner_CreateArchive_CentralSize,
  Lib_Scripts_Runner_CreateArchive_Checksum,
  Lib_Scripts_Runner_CreateArchive_Compressed,
  Lib_Scripts_Runner_CreateArchive_Contents,
  Lib_Scripts_Runner_CreateArchive_EndRecord,
  Lib_Scripts_Runner_CreateArchive_Files,
  Lib_Scripts_Runner_CreateArchive_LocalHeader,
  Lib_Scripts_Runner_CreateArchive_Location,
  Lib_Scripts_Runner_CreateArchive_Name,
  Lib_Scripts_Runner_CreateArchive_Offset,
  Lib_Scripts_Runner_CreateArchive_Parts,
  Lib_Scripts_Runner_CreateArchive_Returns,
  Lib_Scripts_Runner_CreateArchive_UtfFlag,
  Lib_Scripts_Runner_GetArchiveDate_Date,
  Lib_Scripts_Runner_GetArchiveDate_DateParts,
  Lib_Scripts_Runner_GetArchiveDate_Day,
  Lib_Scripts_Runner_GetArchiveDate_Month,
  Lib_Scripts_Runner_GetArchiveDate_Returns,
  Lib_Scripts_Runner_GetArchiveDate_Year,
  Lib_Scripts_Runner_GetLatestVersion_Returns,
  Lib_Scripts_Runner_GetLatestVersion_Sorted,
  Lib_Scripts_Runner_GetLatestVersion_Versions,
  Lib_Scripts_Runner_GetStoreDirectory_Returns,
  Lib_Scripts_Runner_GetVersionDirectory_Location,
  Lib_Scripts_Runner_GetVersionDirectory_Returns,
  Lib_Scripts_Runner_ListFiles_Location,
  Lib_Scripts_Runner_ListFiles_Returns,
  Lib_Scripts_Runner_ListFiles_VersionDirectory,
  Lib_Scripts_Runner_ReadFile_File,
  Lib_Scripts_Runner_ReadFile_FilePath,
  Lib_Scripts_Runner_ReadFile_Location,
  Lib_Scripts_Runner_ReadFile_Returns,
  Lib_Scripts_Runner_ReadFile_VersionDirectory,
  Lib_Scripts_Runner_SortVersions_Returns,
  Lib_Scripts_Runner_SortVersions_Versions,
  Lib_Scripts_Runner_WalkDirectory_Directory,
  Lib_Scripts_Runner_WalkDirectory_Entries,
  Lib_Scripts_Runner_WalkDirectory_Files,
  Lib_Scripts_Runner_WalkDirectory_Prefix,
  Lib_Scripts_Runner_WalkDirectory_RelativePath,
  Lib_Scripts_Runner_WalkDirectory_Returns,
} from '../types/lib/scripts.d.ts';

/**
 * Lib - Scripts.
 *
 * Reads the versioned script store under "scripts/" and packages its files.
 * Pages, download routes, and tests share these helpers at build time.
 *
 * @since 1.0.0
 */
export class Runner {
  /**
   * Lib - Scripts - Create Archive.
   *
   * Bundles every file of one script version into a single ZIP download.
   * Entries use the version date so rebuilt archives stay byte-identical.
   *
   * @param {Lib_Scripts_Runner_CreateArchive_Location} location - Location.
   *
   * @returns {Lib_Scripts_Runner_CreateArchive_Returns}
   *
   * @since 1.0.0
   */
  public static createArchive(location: Lib_Scripts_Runner_CreateArchive_Location): Lib_Scripts_Runner_CreateArchive_Returns {
    const files: Lib_Scripts_Runner_CreateArchive_Files = Runner.listFiles(location);
    const archiveDate: Lib_Scripts_Runner_CreateArchive_ArchiveDate = Runner.getArchiveDate(location['date']);
    const utfFlag: Lib_Scripts_Runner_CreateArchive_UtfFlag = parseInt('0800', 16);
    const parts: Lib_Scripts_Runner_CreateArchive_Parts = [];
    const centralHeaders: Lib_Scripts_Runner_CreateArchive_CentralHeaders = [];

    let offset: Lib_Scripts_Runner_CreateArchive_Offset = 0;

    for (const file of files) {
      const contents: Lib_Scripts_Runner_CreateArchive_Contents = Runner.readFile(location, file);
      const compressed: Lib_Scripts_Runner_CreateArchive_Compressed = deflateRawSync(contents);
      const checksum: Lib_Scripts_Runner_CreateArchive_Checksum = crc32(contents);
      const name: Lib_Scripts_Runner_CreateArchive_Name = Buffer.from(`${location['slug']}/${file}`, 'utf-8');
      const localHeader: Lib_Scripts_Runner_CreateArchive_LocalHeader = Buffer.alloc(30);
      const centralHeader: Lib_Scripts_Runner_CreateArchive_CentralHeader = Buffer.alloc(46);

      // Describe the entry in a local header placed before its data. Headers
      // start zero-filled, so fields that stay zero are not written.
      localHeader.writeUIntLE(parseInt('04034b50', 16), 0, 4);
      localHeader.writeUIntLE(20, 4, 2);
      localHeader.writeUIntLE(utfFlag, 6, 2);
      localHeader.writeUIntLE(8, 8, 2);
      localHeader.writeUIntLE(archiveDate['time'], 10, 2);
      localHeader.writeUIntLE(archiveDate['date'], 12, 2);
      localHeader.writeUIntLE(checksum, 14, 4);
      localHeader.writeUIntLE(compressed.length, 18, 4);
      localHeader.writeUIntLE(contents.length, 22, 4);
      localHeader.writeUIntLE(name.length, 26, 2);

      // Record the same entry in the central directory.
      centralHeader.writeUIntLE(parseInt('02014b50', 16), 0, 4);
      centralHeader.writeUIntLE(20, 4, 2);
      centralHeader.writeUIntLE(20, 6, 2);
      centralHeader.writeUIntLE(utfFlag, 8, 2);
      centralHeader.writeUIntLE(8, 10, 2);
      centralHeader.writeUIntLE(archiveDate['time'], 12, 2);
      centralHeader.writeUIntLE(archiveDate['date'], 14, 2);
      centralHeader.writeUIntLE(checksum, 16, 4);
      centralHeader.writeUIntLE(compressed.length, 20, 4);
      centralHeader.writeUIntLE(contents.length, 24, 4);
      centralHeader.writeUIntLE(name.length, 28, 2);
      centralHeader.writeUIntLE(offset, 42, 4);

      parts.push(localHeader, name, compressed);

      centralHeaders.push(centralHeader, name);

      offset += localHeader.length + name.length + compressed.length;
    }

    const centralSize: Lib_Scripts_Runner_CreateArchive_CentralSize = centralHeaders.reduce((total, centralHeaderPart) => total + centralHeaderPart.length, 0);
    const endRecord: Lib_Scripts_Runner_CreateArchive_EndRecord = Buffer.alloc(22);

    // Close the archive with the end of central directory record.
    endRecord.writeUIntLE(parseInt('06054b50', 16), 0, 4);
    endRecord.writeUIntLE(files.length, 8, 2);
    endRecord.writeUIntLE(files.length, 10, 2);
    endRecord.writeUIntLE(centralSize, 12, 4);
    endRecord.writeUIntLE(offset, 16, 4);

    return Buffer.concat([
      ...parts,
      ...centralHeaders,
      endRecord,
    ]);
  }

  /**
   * Lib - Scripts - Get Latest Version.
   *
   * Picks the highest version number from a script's version history.
   * The "latest" download path and the detail page both depend on it.
   *
   * @param {Lib_Scripts_Runner_GetLatestVersion_Versions} versions - Versions.
   *
   * @returns {Lib_Scripts_Runner_GetLatestVersion_Returns}
   *
   * @since 1.0.0
   */
  public static getLatestVersion(versions: Lib_Scripts_Runner_GetLatestVersion_Versions): Lib_Scripts_Runner_GetLatestVersion_Returns {
    const sorted: Lib_Scripts_Runner_GetLatestVersion_Sorted = Runner.sortVersions(versions);

    return sorted[0];
  }

  /**
   * Lib - Scripts - Get Store Directory.
   *
   * Resolves the "scripts" folder that holds every versioned script copy.
   * Astro runs from the workspace root, so the path is relative to it.
   *
   * @returns {Lib_Scripts_Runner_GetStoreDirectory_Returns}
   *
   * @since 1.0.0
   */
  public static getStoreDirectory(): Lib_Scripts_Runner_GetStoreDirectory_Returns {
    return resolve(process.cwd(), 'scripts');
  }

  /**
   * Lib - Scripts - Get Version Directory.
   *
   * Resolves the folder that holds one version's full copy of a script.
   * Every file listing and download for that version starts here.
   *
   * @param {Lib_Scripts_Runner_GetVersionDirectory_Location} location - Location.
   *
   * @returns {Lib_Scripts_Runner_GetVersionDirectory_Returns}
   *
   * @since 1.0.0
   */
  public static getVersionDirectory(location: Lib_Scripts_Runner_GetVersionDirectory_Location): Lib_Scripts_Runner_GetVersionDirectory_Returns {
    return join(Runner.getStoreDirectory(), location['category'], location['slug'], location['version']);
  }

  /**
   * Lib - Scripts - List Files.
   *
   * Lists every file in a script version as sorted, forward-slash paths.
   * Multi-file scripts such as games keep their nested folder layout.
   *
   * @param {Lib_Scripts_Runner_ListFiles_Location} location - Location.
   *
   * @returns {Lib_Scripts_Runner_ListFiles_Returns}
   *
   * @since 1.0.0
   */
  public static listFiles(location: Lib_Scripts_Runner_ListFiles_Location): Lib_Scripts_Runner_ListFiles_Returns {
    const versionDirectory: Lib_Scripts_Runner_ListFiles_VersionDirectory = Runner.getVersionDirectory(location);

    return Runner.walkDirectory(versionDirectory, '').sort();
  }

  /**
   * Lib - Scripts - Read File.
   *
   * Reads one file of a script version as raw bytes for a download.
   * Bytes are never re-encoded, so every copy matches the original.
   *
   * @param {Lib_Scripts_Runner_ReadFile_Location} location - Location.
   * @param {Lib_Scripts_Runner_ReadFile_File}     file     - File.
   *
   * @returns {Lib_Scripts_Runner_ReadFile_Returns}
   *
   * @since 1.0.0
   */
  public static readFile(location: Lib_Scripts_Runner_ReadFile_Location, file: Lib_Scripts_Runner_ReadFile_File): Lib_Scripts_Runner_ReadFile_Returns {
    const versionDirectory: Lib_Scripts_Runner_ReadFile_VersionDirectory = Runner.getVersionDirectory(location);
    const filePath: Lib_Scripts_Runner_ReadFile_FilePath = join(versionDirectory, file);

    return readFileSync(filePath);
  }

  /**
   * Lib - Scripts - Sort Versions.
   *
   * Orders a version history from newest to oldest by version number.
   * The version history table and the latest lookup read this order.
   *
   * @param {Lib_Scripts_Runner_SortVersions_Versions} versions - Versions.
   *
   * @returns {Lib_Scripts_Runner_SortVersions_Returns}
   *
   * @since 1.0.0
   */
  public static sortVersions(versions: Lib_Scripts_Runner_SortVersions_Versions): Lib_Scripts_Runner_SortVersions_Returns {
    return [...versions].sort((leftVersion, rightVersion) => Runner.compareVersions(rightVersion['version'], leftVersion['version']));
  }

  /**
   * Lib - Scripts - Compare Versions.
   *
   * Compares two "major.minor.patch" strings by their numeric parts.
   * Plain string sorting would rank "1.10.0" below "1.9.0".
   *
   * @param {Lib_Scripts_Runner_CompareVersions_Left}  left  - Left.
   * @param {Lib_Scripts_Runner_CompareVersions_Right} right - Right.
   *
   * @private
   *
   * @returns {Lib_Scripts_Runner_CompareVersions_Returns}
   *
   * @since 1.0.0
   */
  private static compareVersions(left: Lib_Scripts_Runner_CompareVersions_Left, right: Lib_Scripts_Runner_CompareVersions_Right): Lib_Scripts_Runner_CompareVersions_Returns {
    const leftMatch: Lib_Scripts_Runner_CompareVersions_LeftMatch = LIB_REGEX_SEMANTIC_VERSION.exec(left);
    const rightMatch: Lib_Scripts_Runner_CompareVersions_RightMatch = LIB_REGEX_SEMANTIC_VERSION.exec(right);

    if (leftMatch === null || rightMatch === null) {
      return left.localeCompare(right);
    }

    for (let i = 1; i <= 3; i += 1) {
      const difference: Lib_Scripts_Runner_CompareVersions_Difference = Number(leftMatch[i]) - Number(rightMatch[i]);

      if (difference !== 0) {
        return difference;
      }
    }

    return 0;
  }

  /**
   * Lib - Scripts - Get Archive Date.
   *
   * Converts a "YYYY-MM-DD" version date into ZIP's MS-DOS date and time.
   * Archive entries carry the date the version was published.
   *
   * @param {Lib_Scripts_Runner_GetArchiveDate_Date} date - Date.
   *
   * @private
   *
   * @returns {Lib_Scripts_Runner_GetArchiveDate_Returns}
   *
   * @since 1.0.0
   */
  private static getArchiveDate(date: Lib_Scripts_Runner_GetArchiveDate_Date): Lib_Scripts_Runner_GetArchiveDate_Returns {
    const dateParts: Lib_Scripts_Runner_GetArchiveDate_DateParts = date.split('-');
    const year: Lib_Scripts_Runner_GetArchiveDate_Year = Number(dateParts[0]);
    const month: Lib_Scripts_Runner_GetArchiveDate_Month = Number(dateParts[1]);
    const day: Lib_Scripts_Runner_GetArchiveDate_Day = Number(dateParts[2]);

    return {
      date: ((year - 1980) * 512) + (month * 32) + day,
      time: 0,
    };
  }

  /**
   * Lib - Scripts - Walk Directory.
   *
   * Collects file paths below a folder, descending into nested folders.
   * Paths are relative to the version folder and use forward slashes.
   *
   * @param {Lib_Scripts_Runner_WalkDirectory_Directory} directory - Directory.
   * @param {Lib_Scripts_Runner_WalkDirectory_Prefix}    prefix    - Prefix.
   *
   * @private
   *
   * @returns {Lib_Scripts_Runner_WalkDirectory_Returns}
   *
   * @since 1.0.0
   */
  private static walkDirectory(directory: Lib_Scripts_Runner_WalkDirectory_Directory, prefix: Lib_Scripts_Runner_WalkDirectory_Prefix): Lib_Scripts_Runner_WalkDirectory_Returns {
    const entries: Lib_Scripts_Runner_WalkDirectory_Entries = readdirSync(directory, { withFileTypes: true });
    const files: Lib_Scripts_Runner_WalkDirectory_Files = [];

    for (const entry of entries) {
      const relativePath: Lib_Scripts_Runner_WalkDirectory_RelativePath = `${prefix}${entry.name}`;

      // Skip hidden operating system files such as ".DS_Store".
      if (entry.name.startsWith('.') === true) {
        continue;
      }

      if (entry.isDirectory() === true) {
        files.push(...Runner.walkDirectory(join(directory, entry.name), `${relativePath}/`));

        continue;
      }

      if (entry.isFile() === true) {
        files.push(relativePath);
      }
    }

    return files;
  }
}
