import { VitestCoverage } from '@cbnventures/nova/toolkit';
import { defineConfig } from 'vitest/config';

/**
 * Vitest Configuration.
 *
 * Discovers source-level and workspace-level unit tests.
 * Keeps framework checks isolated from neighboring monorepo workspaces.
 *
 * @since 0.0.0
 */
export default defineConfig({
  test: {
    include: [
      'src/**/*.test.ts',
      'tests/**/*.test.ts',
    ],
    passWithNoTests: true,
    globals: false,
    testTimeout: 30000, // 30 seconds.
    coverage: VitestCoverage.options(),
  },
});
