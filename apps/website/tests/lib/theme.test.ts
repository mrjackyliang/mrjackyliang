import {
  describe,
  expect,
  it,
} from 'vitest';

import { Runner } from '../../src/lib/theme.js';

import type {
  Tests_Lib_Theme_ThemeResolution_GetNextChoice_Choices,
  Tests_Lib_Theme_ThemeResolution_ParseChoice_StoredValues,
} from '../../src/types/tests/lib/theme.d.ts';

/**
 * Theme - Theme Resolution.
 *
 * Confirms how a stored choice becomes a theme, so the header toggle and the
 * head script agree on "system", "light", and "dark".
 *
 * @since 1.0.0
 */
describe('Theme resolution', () => {
  it('reads only "light" and "dark" back as explicit choices', () => {
    const storedValues: Tests_Lib_Theme_ThemeResolution_ParseChoice_StoredValues = [
      null,
      undefined,
      '',
      'system',
      'Dark',
      'sepia',
    ];

    expect(Runner.parseChoice('light')).toBe('light');

    expect(Runner.parseChoice('dark')).toBe('dark');

    for (const storedValue of storedValues) {
      expect(Runner.parseChoice(storedValue)).toBe('system');
    }

    return;
  });

  it('follows the system preference only for the system choice', () => {
    expect(Runner.resolveTheme('system', false)).toBe('light');

    expect(Runner.resolveTheme('system', true)).toBe('dark');

    expect(Runner.resolveTheme('light', true)).toBe('light');

    expect(Runner.resolveTheme('dark', false)).toBe('dark');

    return;
  });

  it('cycles from system to light to dark and back to system', () => {
    const choices: Tests_Lib_Theme_ThemeResolution_GetNextChoice_Choices = [
      Runner.getNextChoice('system'),
      Runner.getNextChoice('light'),
      Runner.getNextChoice('dark'),
    ];

    expect(choices).toEqual([
      'light',
      'dark',
      'system',
    ]);

    return;
  });

  return;
});
