/**
 * Lib - Regex - Calendar Date.
 *
 * Matches a "YYYY-MM-DD" date such as "2026-11-21" in a version entry.
 * The scripts collection rejects any other date format at build time.
 *
 * @since 1.0.0
 */
export const LIB_REGEX_CALENDAR_DATE = /^\d{4}-\d{2}-\d{2}$/;

/**
 * Lib - Regex - Script JSON Suffix.
 *
 * Matches the trailing "/script.json" of a script metadata file path.
 * Removing it turns the path into the "<category>/<slug>" entry ID.
 *
 * @since 1.0.0
 */
export const LIB_REGEX_SCRIPT_JSON_SUFFIX = /\/script\.json$/;

/**
 * Lib - Regex - Semantic Version.
 *
 * Matches a plain "major.minor.patch" version folder name such as "1.0.0".
 * Script version folders and version entries both follow this shape.
 *
 * @since 1.0.0
 */
export const LIB_REGEX_SEMANTIC_VERSION = /^(\d+)\.(\d+)\.(\d+)$/;
