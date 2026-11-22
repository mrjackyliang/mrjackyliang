/**
 * Shared - Script Location.
 *
 * @since 1.0.0
 */
export type Shared_ScriptLocation_Category = string;

export type Shared_ScriptLocation_Slug = string;

export type Shared_ScriptLocation_Version = string;

export type Shared_ScriptLocation = {
  category: Shared_ScriptLocation_Category;
  slug: Shared_ScriptLocation_Slug;
  version: Shared_ScriptLocation_Version;
};

/**
 * Shared - Script Version.
 *
 * @since 1.0.0
 */
export type Shared_ScriptVersion_Version = string;

export type Shared_ScriptVersion_Date = string;

export type Shared_ScriptVersion_Notes = string;

export type Shared_ScriptVersion = {
  version: Shared_ScriptVersion_Version;
  date: Shared_ScriptVersion_Date;
  notes: Shared_ScriptVersion_Notes;
};

export type Shared_ScriptVersions = Shared_ScriptVersion[];

/**
 * Shared - Theme.
 *
 * @since 1.0.0
 */
export type Shared_Theme = 'light' | 'dark';

/**
 * Shared - Theme Choice.
 *
 * @since 1.0.0
 */
export type Shared_ThemeChoice = 'system' | Shared_Theme;
