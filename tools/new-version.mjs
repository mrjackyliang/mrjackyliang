import {
  copyFileSync,
  existsSync,
  mkdirSync,
  readdirSync,
  readFileSync,
  writeFileSync,
} from 'node:fs';
import { join, resolve } from 'node:path';

/**
 * New Version - Create Version.
 *
 * Copies a script's latest version folder to a new version folder and adds the
 * matching entry to "script.json", ready for the files and notes to be edited.
 *
 * Usage: "npm run new-version -- <category>/<slug> [<version> | major | minor | patch]"
 *
 * @returns {void}
 *
 * @since 0.0.0
 */
function createVersion() {
  const scriptId = process.argv[2] ?? '';
  const versionArgument = process.argv[3] ?? 'patch';
  const scriptIdParts = scriptId.split('/');

  if (scriptIdParts.length !== 2 || scriptIdParts.includes('') === true) {
    process.stderr.write('new-version: Pass the script as "<category>/<slug>", for example "games/boggle-game".\n');

    process.exitCode = 1;

    return;
  }

  const storeDirectory = resolve(process.cwd(), 'apps', 'website', 'scripts');
  const scriptDirectory = join(storeDirectory, scriptIdParts[0] ?? '', scriptIdParts[1] ?? '');
  const metadataPath = join(scriptDirectory, 'script.json');

  if (existsSync(metadataPath) === false) {
    process.stderr.write(`new-version: No "script.json" found for "${scriptId}" in "apps/website/scripts".\n`);

    process.exitCode = 1;

    return;
  }

  const metadata = JSON.parse(readFileSync(metadataPath, 'utf-8'));
  const versions = metadata['versions'];
  const latestVersion = findLatestVersion(versions);

  if (latestVersion === undefined) {
    process.stderr.write(`new-version: "${scriptId}" has no versions to copy.\n`);

    process.exitCode = 1;

    return;
  }

  const nextVersion = resolveNextVersion(latestVersion, versionArgument);

  if (nextVersion === undefined) {
    process.stderr.write(`new-version: "${versionArgument}" is not "major", "minor", "patch", or a "major.minor.patch" version.\n`);

    process.exitCode = 1;

    return;
  }

  const nextDirectory = join(scriptDirectory, nextVersion);

  if (
    compareVersions(nextVersion, latestVersion) <= 0
    || existsSync(nextDirectory) === true
  ) {
    process.stderr.write(`new-version: Version "${nextVersion}" must be newer than "${latestVersion}" and must not exist yet.\n`);

    process.exitCode = 1;

    return;
  }

  const latestDirectory = join(scriptDirectory, latestVersion);

  // Copy the full latest version, so the new version starts as an exact copy.
  copyDirectory(latestDirectory, nextDirectory);

  // Record the new version first. Its notes stay empty until they are written.
  versions.unshift({
    version: nextVersion,
    date: getToday(),
    notes: '',
  });

  const metadataJson = JSON.stringify(metadata, null, 2);

  writeFileSync(metadataPath, `${metadataJson}\n`, 'utf-8');

  const nextSteps = [
    `new-version: Copied "${scriptId}" ${latestVersion} to ${nextVersion}.`,
    `  1. Edit the files in "apps/website/scripts/${scriptId}/${nextVersion}/".`,
    `  2. Write the ${nextVersion} notes in "apps/website/scripts/${scriptId}/script.json".`,
    '  3. Run "npm run check" and "npm run build" from the project root.',
  ];

  process.stdout.write(`${nextSteps.join('\n')}\n`);

  return;
}

/**
 * New Version - Compare Versions.
 *
 * Compares two "major.minor.patch" strings by their numeric parts, so that
 * "1.10.0" ranks above "1.9.0" when the newest version is picked.
 *
 * @param {string} left  - Left.
 * @param {string} right - Right.
 *
 * @returns {number}
 *
 * @since 0.0.0
 */
function compareVersions(left, right) {
  const leftParts = left.split('.').map(Number);
  const rightParts = right.split('.').map(Number);

  for (let i = 0; i < 3; i += 1) {
    const difference = (leftParts[i] ?? 0) - (rightParts[i] ?? 0);

    if (difference !== 0) {
      return difference;
    }
  }

  return 0;
}

/**
 * New Version - Copy Directory.
 *
 * Copies a version folder file by file, including nested folders such as the
 * "console" and "gui" folders of a game. Hidden files are left behind.
 *
 * @param {string} source      - Source.
 * @param {string} destination - Destination.
 *
 * @returns {void}
 *
 * @since 0.0.0
 */
function copyDirectory(source, destination) {
  const entries = readdirSync(source, {
    withFileTypes: true,
  });

  mkdirSync(destination, {
    recursive: true,
  });

  for (const entry of entries) {
    const sourcePath = join(source, entry.name);
    const destinationPath = join(destination, entry.name);

    if (entry.name.startsWith('.') === true) {
      continue;
    }

    if (entry.isDirectory() === true) {
      copyDirectory(sourcePath, destinationPath);

      continue;
    }

    if (entry.isFile() === true) {
      copyFileSync(sourcePath, destinationPath);
    }
  }

  return;
}

/**
 * New Version - Find Latest Version.
 *
 * Picks the highest version number from the "versions" list of "script.json".
 * The list order does not matter, so hand-edited files still work.
 *
 * @param {unknown} versions - Versions.
 *
 * @returns {string | undefined}
 *
 * @since 0.0.0
 */
function findLatestVersion(versions) {
  if (Array.isArray(versions) === false) {
    return undefined;
  }

  const versionNumbers = versions
    .map((version) => version['version'])
    .filter((versionNumber) => typeof versionNumber === 'string');

  return versionNumbers.sort((leftVersionNumber, rightVersionNumber) => compareVersions(rightVersionNumber, leftVersionNumber))[0];
}

/**
 * New Version - Get Today.
 *
 * Formats the current local date as "YYYY-MM-DD" for the new version entry.
 * The scripts collection only accepts dates written in this format.
 *
 * @returns {string}
 *
 * @since 0.0.0
 */
function getToday() {
  const today = new Date();
  const year = String(today.getFullYear());
  const month = String(today.getMonth() + 1).padStart(2, '0');
  const day = String(today.getDate()).padStart(2, '0');

  return `${year}-${month}-${day}`;
}

/**
 * New Version - Is Version Number.
 *
 * Checks that a value is a plain "major.minor.patch" version such as "1.2.0".
 * Version folders must use this shape, so other input is rejected early.
 *
 * @param {string} value - Value.
 *
 * @returns {boolean}
 *
 * @since 0.0.0
 */
function isVersionNumber(value) {
  const valueParts = value.split('.');

  return valueParts.length === 3 && valueParts.every((valuePart) => valuePart !== '' && String(Number(valuePart)) === valuePart);
}

/**
 * New Version - Resolve Next Version.
 *
 * Turns the version argument into the next version number. "major", "minor",
 * and "patch" bump the latest version; anything else must be a full version.
 *
 * @param {string} latestVersion   - Latest version.
 * @param {string} versionArgument - Version argument.
 *
 * @returns {string | undefined}
 *
 * @since 0.0.0
 */
function resolveNextVersion(latestVersion, versionArgument) {
  const latestParts = latestVersion.split('.').map(Number);
  const major = latestParts[0] ?? 0;
  const minor = latestParts[1] ?? 0;
  const patch = latestParts[2] ?? 0;

  switch (versionArgument) {
    case 'major': {
      return `${major + 1}.0.0`;
    }

    case 'minor': {
      return `${major}.${minor + 1}.0`;
    }

    case 'patch': {
      return `${major}.${minor}.${patch + 1}`;
    }

    default: {
      return (isVersionNumber(versionArgument) === true) ? versionArgument : undefined;
    }
  }
}

createVersion();
