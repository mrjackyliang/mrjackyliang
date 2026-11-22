import type { APIContext } from 'astro';
import type { CollectionEntry } from 'astro:content';

import type {
  Shared_ScriptLocation,
  Shared_ScriptVersion,
  Shared_ScriptVersions,
} from '../shared.d.ts';

/**
 * Lib - Routes - Get Archive Paths.
 *
 * @since 1.0.0
 */
export type Lib_Routes_Runner_GetArchivePaths_Returns_Params_Category = string;

export type Lib_Routes_Runner_GetArchivePaths_Returns_Params_Slug = string;

export type Lib_Routes_Runner_GetArchivePaths_Returns_Params_Version = string;

export type Lib_Routes_Runner_GetArchivePaths_Returns_Params = {
  category: Lib_Routes_Runner_GetArchivePaths_Returns_Params_Category;
  slug: Lib_Routes_Runner_GetArchivePaths_Returns_Params_Slug;
  version: Lib_Routes_Runner_GetArchivePaths_Returns_Params_Version;
};

export type Lib_Routes_Runner_GetArchivePaths_Returns_Props = Lib_Routes_Runner_GetTargets_Target;

export type Lib_Routes_Runner_GetArchivePaths_Returns_Path = {
  params: Lib_Routes_Runner_GetArchivePaths_Returns_Params;
  props: Lib_Routes_Runner_GetArchivePaths_Returns_Props;
};

export type Lib_Routes_Runner_GetArchivePaths_Returns = Promise<Lib_Routes_Runner_GetArchivePaths_Returns_Path[]>;

export type Lib_Routes_Runner_GetArchivePaths_Targets = Lib_Routes_Runner_GetTargets_Target[];

/**
 * Lib - Routes - Get File Paths.
 *
 * @since 1.0.0
 */
export type Lib_Routes_Runner_GetFilePaths_Returns = Promise<Lib_Routes_Runner_GetFilePaths_Paths>;

export type Lib_Routes_Runner_GetFilePaths_Targets = Lib_Routes_Runner_GetTargets_Target[];

export type Lib_Routes_Runner_GetFilePaths_Paths_Params_Category = string;

export type Lib_Routes_Runner_GetFilePaths_Paths_Params_Slug = string;

export type Lib_Routes_Runner_GetFilePaths_Paths_Params_Version = string;

export type Lib_Routes_Runner_GetFilePaths_Paths_Params_File = string;

export type Lib_Routes_Runner_GetFilePaths_Paths_Params = {
  category: Lib_Routes_Runner_GetFilePaths_Paths_Params_Category;
  slug: Lib_Routes_Runner_GetFilePaths_Paths_Params_Slug;
  version: Lib_Routes_Runner_GetFilePaths_Paths_Params_Version;
  file: Lib_Routes_Runner_GetFilePaths_Paths_Params_File;
};

export type Lib_Routes_Runner_GetFilePaths_Paths_Props_File = string;

export type Lib_Routes_Runner_GetFilePaths_Paths_Props = Lib_Routes_Runner_GetTargets_Target & {
  file: Lib_Routes_Runner_GetFilePaths_Paths_Props_File;
};

export type Lib_Routes_Runner_GetFilePaths_Paths_Path = {
  params: Lib_Routes_Runner_GetFilePaths_Paths_Params;
  props: Lib_Routes_Runner_GetFilePaths_Paths_Props;
};

export type Lib_Routes_Runner_GetFilePaths_Paths = Lib_Routes_Runner_GetFilePaths_Paths_Path[];

/**
 * Lib - Routes - Get Targets.
 *
 * @since 1.0.0
 */
export type Lib_Routes_Runner_GetTargets_Returns = Promise<Lib_Routes_Runner_GetTargets_Targets>;

export type Lib_Routes_Runner_GetTargets_Entries = CollectionEntry<'scripts'>[];

export type Lib_Routes_Runner_GetTargets_Target_Date = string;

export type Lib_Routes_Runner_GetTargets_Target_Label = string;

export type Lib_Routes_Runner_GetTargets_Target = Shared_ScriptLocation & {
  date: Lib_Routes_Runner_GetTargets_Target_Date;
  label: Lib_Routes_Runner_GetTargets_Target_Label;
};

export type Lib_Routes_Runner_GetTargets_Targets = Lib_Routes_Runner_GetTargets_Target[];

export type Lib_Routes_Runner_GetTargets_EntryIdParts = string[];

export type Lib_Routes_Runner_GetTargets_EntryCategory = string;

export type Lib_Routes_Runner_GetTargets_EntrySlug = string;

export type Lib_Routes_Runner_GetTargets_EntryVersions = Shared_ScriptVersions;

export type Lib_Routes_Runner_GetTargets_EntryLatest = Shared_ScriptVersion | undefined;

/**
 * Lib - Routes - Serve Archive.
 *
 * @since 1.0.0
 */
export type Lib_Routes_Runner_ServeArchive_Context = APIContext;

export type Lib_Routes_Runner_ServeArchive_Returns = Response;

export type Lib_Routes_Runner_ServeArchive_Archive = Buffer;

/**
 * Lib - Routes - Serve File.
 *
 * @since 1.0.0
 */
export type Lib_Routes_Runner_ServeFile_Context = APIContext;

export type Lib_Routes_Runner_ServeFile_Returns = Response;

export type Lib_Routes_Runner_ServeFile_File = string;

export type Lib_Routes_Runner_ServeFile_Contents = Buffer;
