import type {
  Lib_Theme_Runner_Choices,
  Lib_Theme_Runner_GetNextChoice_Choice,
  Lib_Theme_Runner_GetNextChoice_Index,
  Lib_Theme_Runner_GetNextChoice_Returns,
  Lib_Theme_Runner_ParseChoice_Returns,
  Lib_Theme_Runner_ParseChoice_Stored,
  Lib_Theme_Runner_ResolveTheme_Choice,
  Lib_Theme_Runner_ResolveTheme_PrefersDark,
  Lib_Theme_Runner_ResolveTheme_Returns,
} from '../types/lib/theme.d.ts';

/**
 * Lib - Theme.
 *
 * Decides which color theme the site shows from the visitor's choice.
 * "System" follows the operating system, while "light" and "dark" pin it.
 *
 * @since 1.0.0
 */
export class Runner {
  /**
   * Lib - Theme - Choices.
   *
   * Lists the theme choices in the order the header toggle cycles through.
   * "System" comes first because it is the default for every visitor.
   *
   * @private
   *
   * @since 1.0.0
   */
  static readonly #choices: Lib_Theme_Runner_Choices = [
    'system',
    'light',
    'dark',
  ];

  /**
   * Lib - Theme - Get Next Choice.
   *
   * Returns the choice after the current one in the toggle cycle.
   * The cycle wraps from "dark" back to "system".
   *
   * @param {Lib_Theme_Runner_GetNextChoice_Choice} choice - Choice.
   *
   * @returns {Lib_Theme_Runner_GetNextChoice_Returns}
   *
   * @since 1.0.0
   */
  public static getNextChoice(choice: Lib_Theme_Runner_GetNextChoice_Choice): Lib_Theme_Runner_GetNextChoice_Returns {
    const index: Lib_Theme_Runner_GetNextChoice_Index = Runner.#choices.indexOf(choice);

    return Runner.#choices[(index + 1) % Runner.#choices.length] ?? 'system';
  }

  /**
   * Lib - Theme - Parse Choice.
   *
   * Reads a stored value back into a choice. Anything other than "light" or
   * "dark", including a missing or blocked value, means "system".
   *
   * @param {Lib_Theme_Runner_ParseChoice_Stored} stored - Stored.
   *
   * @returns {Lib_Theme_Runner_ParseChoice_Returns}
   *
   * @since 1.0.0
   */
  public static parseChoice(stored: Lib_Theme_Runner_ParseChoice_Stored): Lib_Theme_Runner_ParseChoice_Returns {
    if (stored === 'light' || stored === 'dark') {
      return stored;
    }

    return 'system';
  }

  /**
   * Lib - Theme - Resolve Theme.
   *
   * Turns a choice into the theme on screen. "System" uses the operating
   * system preference, and light is the fallback when there is none.
   *
   * @param {Lib_Theme_Runner_ResolveTheme_Choice}      choice      - Choice.
   * @param {Lib_Theme_Runner_ResolveTheme_PrefersDark} prefersDark - Prefers dark.
   *
   * @returns {Lib_Theme_Runner_ResolveTheme_Returns}
   *
   * @since 1.0.0
   */
  public static resolveTheme(choice: Lib_Theme_Runner_ResolveTheme_Choice, prefersDark: Lib_Theme_Runner_ResolveTheme_PrefersDark): Lib_Theme_Runner_ResolveTheme_Returns {
    if (choice !== 'system') {
      return choice;
    }

    return (prefersDark === true) ? 'dark' : 'light';
  }
}
