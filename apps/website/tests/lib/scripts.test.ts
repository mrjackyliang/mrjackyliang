import { inflateRawSync } from 'node:zlib';

import {
  describe,
  expect,
  it,
} from 'vitest';

import { Runner } from '../../src/lib/scripts.js';

import type {
  Tests_Lib_Scripts_ScriptsStore_CreateArchive_Archive,
  Tests_Lib_Scripts_ScriptsStore_CreateArchive_CompressedSize,
  Tests_Lib_Scripts_ScriptsStore_CreateArchive_Contents,
  Tests_Lib_Scripts_ScriptsStore_CreateArchive_Entry,
  Tests_Lib_Scripts_ScriptsStore_CreateArchive_NameLength,
  Tests_Lib_Scripts_ScriptsStore_ListFiles_Files,
  Tests_Lib_Scripts_ScriptsStore_SortVersions_Versions,
} from '../../src/types/tests/lib/scripts.d.ts';

/**
 * Scripts - Scripts Store.
 *
 * Confirms the version ordering, file listing, and ZIP output that the
 * download routes build from the versioned script store.
 *
 * @since 1.0.0
 */
describe('Scripts store', () => {
  it('sorts versions from newest to oldest by number', () => {
    const versions: Tests_Lib_Scripts_ScriptsStore_SortVersions_Versions = [
      {
        version: '1.9.0',
        date: '2026-11-21',
        notes: 'Nine.',
      },
      {
        version: '1.10.0',
        date: '2026-11-22',
        notes: 'Ten.',
      },
      {
        version: '1.0.0',
        date: '2026-11-20',
        notes: 'One.',
      },
    ];

    expect(Runner.sortVersions(versions).map((version) => version['version'])).toEqual([
      '1.10.0',
      '1.9.0',
      '1.0.0',
    ]);

    expect(Runner.getLatestVersion(versions)).toEqual(versions[1]);

    return;
  });

  it('lists nested files with forward slashes', () => {
    const files: Tests_Lib_Scripts_ScriptsStore_ListFiles_Files = Runner.listFiles({
      category: 'games',
      slug: 'tile-matching-game',
      version: '1.1.1',
    });

    expect(files).toEqual([
      'console/TileMatchingGame.java',
      'gui/TileMatchingGame.java',
      'gui/UserInterface.java',
      'gui/Utility.java',
      'gui/logo.png',
    ]);

    return;
  });

  it('creates a ZIP archive whose first entry inflates to the original file', () => {
    const archive: Tests_Lib_Scripts_ScriptsStore_CreateArchive_Archive = Runner.createArchive({
      category: 'ti-84',
      slug: 'quadrtic',
      version: '1.0.0',
      date: '2026-11-21',
    });
    const contents: Tests_Lib_Scripts_ScriptsStore_CreateArchive_Contents = Runner.readFile({
      category: 'ti-84',
      slug: 'quadrtic',
      version: '1.0.0',
    }, 'QUADRTIC.py');
    const nameLength: Tests_Lib_Scripts_ScriptsStore_CreateArchive_NameLength = archive.readUInt16LE(26);
    const compressedSize: Tests_Lib_Scripts_ScriptsStore_CreateArchive_CompressedSize = archive.readUInt32LE(18);
    const entry: Tests_Lib_Scripts_ScriptsStore_CreateArchive_Entry = archive.subarray(30 + nameLength, 30 + nameLength + compressedSize);

    expect(archive.readUInt32LE(0)).toBe(parseInt('04034b50', 16));

    expect(archive.subarray(30, 30 + nameLength).toString('utf-8')).toBe('quadrtic/QUADRTIC.py');

    expect(inflateRawSync(entry).equals(contents)).toBe(true);

    return;
  });

  return;
});
