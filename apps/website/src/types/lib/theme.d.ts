import type { Shared_Theme, Shared_ThemeChoice } from '../shared.d.ts';

/**
 * Lib - Theme - Choices.
 *
 * @since 1.0.0
 */
export type Lib_Theme_Runner_Choices = Shared_ThemeChoice[];

/**
 * Lib - Theme - Get Next Choice.
 *
 * @since 1.0.0
 */
export type Lib_Theme_Runner_GetNextChoice_Choice = Shared_ThemeChoice;

export type Lib_Theme_Runner_GetNextChoice_Returns = Shared_ThemeChoice;

export type Lib_Theme_Runner_GetNextChoice_Index = number;

/**
 * Lib - Theme - Parse Choice.
 *
 * @since 1.0.0
 */
export type Lib_Theme_Runner_ParseChoice_Stored = string | null | undefined;

export type Lib_Theme_Runner_ParseChoice_Returns = Shared_ThemeChoice;

/**
 * Lib - Theme - Resolve Theme.
 *
 * @since 1.0.0
 */
export type Lib_Theme_Runner_ResolveTheme_Choice = Shared_ThemeChoice;

export type Lib_Theme_Runner_ResolveTheme_PrefersDark = boolean;

export type Lib_Theme_Runner_ResolveTheme_Returns = Shared_Theme;
