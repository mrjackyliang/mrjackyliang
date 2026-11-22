import type { Dirent } from 'node:fs';

import type {
  Shared_ScriptLocation,
  Shared_ScriptVersion,
  Shared_ScriptVersions,
} from '../shared.d.ts';

/**
 * Lib - Scripts - Compare Versions.
 *
 * @since 1.0.0
 */
export type Lib_Scripts_Runner_CompareVersions_Left = string;

export type Lib_Scripts_Runner_CompareVersions_Right = string;

export type Lib_Scripts_Runner_CompareVersions_Returns = number;

export type Lib_Scripts_Runner_CompareVersions_LeftMatch = RegExpExecArray | null;

export type Lib_Scripts_Runner_CompareVersions_RightMatch = RegExpExecArray | null;

export type Lib_Scripts_Runner_CompareVersions_Difference = number;

/**
 * Lib - Scripts - Create Archive.
 *
 * @since 1.0.0
 */
export type Lib_Scripts_Runner_CreateArchive_Location_Date = string;

export type Lib_Scripts_Runner_CreateArchive_Location = Shared_ScriptLocation & {
  date: Lib_Scripts_Runner_CreateArchive_Location_Date;
};

export type Lib_Scripts_Runner_CreateArchive_Returns = Buffer;

export type Lib_Scripts_Runner_CreateArchive_Files = string[];

export type Lib_Scripts_Runner_CreateArchive_ArchiveDate_Date = number;

export type Lib_Scripts_Runner_CreateArchive_ArchiveDate_Time = number;

export type Lib_Scripts_Runner_CreateArchive_ArchiveDate = {
  date: Lib_Scripts_Runner_CreateArchive_ArchiveDate_Date;
  time: Lib_Scripts_Runner_CreateArchive_ArchiveDate_Time;
};

export type Lib_Scripts_Runner_CreateArchive_UtfFlag = number;

export type Lib_Scripts_Runner_CreateArchive_Parts = Buffer[];

export type Lib_Scripts_Runner_CreateArchive_CentralHeaders = Buffer[];

export type Lib_Scripts_Runner_CreateArchive_Offset = number;

export type Lib_Scripts_Runner_CreateArchive_Contents = Buffer;

export type Lib_Scripts_Runner_CreateArchive_Compressed = Buffer;

export type Lib_Scripts_Runner_CreateArchive_Checksum = number;

export type Lib_Scripts_Runner_CreateArchive_Name = Buffer;

export type Lib_Scripts_Runner_CreateArchive_LocalHeader = Buffer;

export type Lib_Scripts_Runner_CreateArchive_CentralHeader = Buffer;

export type Lib_Scripts_Runner_CreateArchive_CentralSize = number;

export type Lib_Scripts_Runner_CreateArchive_EndRecord = Buffer;

/**
 * Lib - Scripts - Get Archive Date.
 *
 * @since 1.0.0
 */
export type Lib_Scripts_Runner_GetArchiveDate_Date = string;

export type Lib_Scripts_Runner_GetArchiveDate_Returns_Date = number;

export type Lib_Scripts_Runner_GetArchiveDate_Returns_Time = number;

export type Lib_Scripts_Runner_GetArchiveDate_Returns = {
  date: Lib_Scripts_Runner_GetArchiveDate_Returns_Date;
  time: Lib_Scripts_Runner_GetArchiveDate_Returns_Time;
};

export type Lib_Scripts_Runner_GetArchiveDate_DateParts = string[];

export type Lib_Scripts_Runner_GetArchiveDate_Year = number;

export type Lib_Scripts_Runner_GetArchiveDate_Month = number;

export type Lib_Scripts_Runner_GetArchiveDate_Day = number;

/**
 * Lib - Scripts - Get Latest Version.
 *
 * @since 1.0.0
 */
export type Lib_Scripts_Runner_GetLatestVersion_Versions = Shared_ScriptVersions;

export type Lib_Scripts_Runner_GetLatestVersion_Returns = Shared_ScriptVersion | undefined;

export type Lib_Scripts_Runner_GetLatestVersion_Sorted = Shared_ScriptVersions;

/**
 * Lib - Scripts - Get Store Directory.
 *
 * @since 1.0.0
 */
export type Lib_Scripts_Runner_GetStoreDirectory_Returns = string;

/**
 * Lib - Scripts - Get Version Directory.
 *
 * @since 1.0.0
 */
export type Lib_Scripts_Runner_GetVersionDirectory_Location = Shared_ScriptLocation;

export type Lib_Scripts_Runner_GetVersionDirectory_Returns = string;

/**
 * Lib - Scripts - List Files.
 *
 * @since 1.0.0
 */
export type Lib_Scripts_Runner_ListFiles_Location = Shared_ScriptLocation;

export type Lib_Scripts_Runner_ListFiles_Returns = string[];

export type Lib_Scripts_Runner_ListFiles_VersionDirectory = string;

/**
 * Lib - Scripts - Read File.
 *
 * @since 1.0.0
 */
export type Lib_Scripts_Runner_ReadFile_Location = Shared_ScriptLocation;

export type Lib_Scripts_Runner_ReadFile_File = string;

export type Lib_Scripts_Runner_ReadFile_Returns = Buffer;

export type Lib_Scripts_Runner_ReadFile_VersionDirectory = string;

export type Lib_Scripts_Runner_ReadFile_FilePath = string;

/**
 * Lib - Scripts - Sort Versions.
 *
 * @since 1.0.0
 */
export type Lib_Scripts_Runner_SortVersions_Versions = Shared_ScriptVersions;

export type Lib_Scripts_Runner_SortVersions_Returns = Shared_ScriptVersions;

/**
 * Lib - Scripts - Walk Directory.
 *
 * @since 1.0.0
 */
export type Lib_Scripts_Runner_WalkDirectory_Directory = string;

export type Lib_Scripts_Runner_WalkDirectory_Prefix = string;

export type Lib_Scripts_Runner_WalkDirectory_Returns = string[];

export type Lib_Scripts_Runner_WalkDirectory_Entries = Dirent[];

export type Lib_Scripts_Runner_WalkDirectory_Files = string[];

export type Lib_Scripts_Runner_WalkDirectory_RelativePath = string;
