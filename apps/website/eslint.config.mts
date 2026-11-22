import {
  dxCodeStyle,
  dxIgnore,
  fwAstro,
  langJavascript,
  langTypescript,
  novaRules,
  runtimeBrowser,
} from '@cbnventures/nova/presets/eslint';

/**
 * ESLint Configuration.
 *
 * Composes Nova's browser, TypeScript, and Astro framework contracts.
 *
 * @since 0.0.0
 */
export default [
  ...dxIgnore,
  ...dxCodeStyle,
  ...langJavascript,
  ...langTypescript,
  ...fwAstro,
  ...runtimeBrowser,
  {
    // The versioned script store holds published downloads verbatim, so the
    // project lint rules never apply to the files inside it.
    name: 'custom-ignores',
    ignores: ['scripts/**'],
  },
  {
    name: 'custom-tsconfig',
    files: [
      '**/*.cts',
      '**/*.mts',
      '**/*.ts',
      '**/*.tsx',
    ],
    languageOptions: {
      parserOptions: {
        project: [
          './tsconfig.astro.json',
          './tsconfig.config.json',
          './tsconfig.tests.json',
        ],
      },
    },
  },
  ...novaRules,
  {
    name: 'custom-nova-rules',
    files: [
      '**/*.cjs',
      '**/*.cts',
      '**/*.js',
      '**/*.jsx',
      '**/*.mjs',
      '**/*.mts',
      '**/*.ts',
      '**/*.tsx',
    ],
    rules: {
      '@cbnventures/nova/no-regex-literals': [
        'error',
        {
          ignoreFiles: [],
          regexFile: './src/lib/regex.ts',
        },
      ],
      '@cbnventures/nova/require-jsdoc-hierarchy': [
        'error',
        {
          anchorDirectories: ['src'],
          ignoreFiles: [
            './astro.config.mjs',
            './eslint.config.mts',
            './vitest.config.mts',
          ],
          knownNames: {},
          stripDirectories: ['types'],
        },
      ],

      // Astro reads "content.config.ts" by name, and dynamic routes need
      // bracketed file names, so these files cannot be kebab-case.
      '@cbnventures/nova/require-kebab-case-filename': [
        'error',
        {
          extraExtensions: [],
          ignoreFiles: [
            './astro.config.mjs',
            './eslint.config.mts',
            './src/content.config.ts',
            './src/pages/robots.txt.ts',
            './src/pages/site.webmanifest.ts',
            './src/pages/scripts/[category]/[slug]/[version].zip.ts',
            './src/pages/scripts/[category]/[slug]/[version]/[...file].ts',
            './vitest.config.mts',
          ],
        },
      ],
    },
  },
];
