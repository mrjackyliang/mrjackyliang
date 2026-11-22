import { defineCollection } from 'astro:content';
import { file, glob } from 'astro/loaders';
import { z } from 'astro/zod';

import { LIB_REGEX_CALENDAR_DATE, LIB_REGEX_SCRIPT_JSON_SUFFIX, LIB_REGEX_SEMANTIC_VERSION } from './lib/regex.js';

/**
 * Content - Categories.
 *
 * Lists the five script categories with the titles and descriptions from
 * "scripts/categories.json", in the order the scripts page shows them.
 *
 * @since 1.0.0
 */
const categories = defineCollection({
  loader: file('./scripts/categories.json'),
  schema: z.object({
    title: z.string(),
    description: z.string(),
    order: z.number(),
  }),
});

/**
 * Content - Scripts.
 *
 * Loads one entry per "scripts/<category>/<slug>/script.json" file. The entry
 * ID is "<category>/<slug>", which matches the script's folder and URL.
 *
 * @since 1.0.0
 */
const scripts = defineCollection({
  loader: glob({
    pattern: '*/*/script.json',
    base: './scripts',
    generateId: (options) => options.entry.replace(LIB_REGEX_SCRIPT_JSON_SUFFIX, ''),
  }),
  schema: z.object({
    title: z.string(),
    category: z.string(),
    description: z.string(),
    language: z.string(),
    versions: z.array(z.object({
      version: z.string().regex(LIB_REGEX_SEMANTIC_VERSION),
      date: z.string().regex(LIB_REGEX_CALENDAR_DATE),
      notes: z.string().min(1),
    })).min(1),
  }),
});

/**
 * Content - Collections.
 *
 * Registers the collections Astro loads at build time, so the scripts pages
 * and download routes can read typed category and script entries.
 *
 * @since 1.0.0
 */
export const collections = {
  categories,
  scripts,
};
