EditorConfig
=============

[Back to Conventions](https://github.com/mrjackyliang/mrjackyliang/tree/main/conventions)

1. Each repository is required to include an `.editorconfig` file at the project's root directory.
2. All `.editorconfig` files managed by a single organization should maintain uniformity across all projects to streamline maintenance efforts.
3. Given the limited available [properties](https://github.com/editorconfig/editorconfig/wiki/EditorConfig-Properties) in `.editorconfig` files, it's advisable for organizations to stick to a single brand of IDEs (e.g. JetBrains or Visual Studio Code) to avoid unnecessary redundancy with vendor prefixes (e.g. two of the same rules but each rule is designed for a specific IDE).
4. When utilizing JetBrains IDEs, it's recommended to disable the inspection rules for "No matching files" and "Unknown property" since enforcing these rules would be redundant given the commitment to maintain uniformity.

### Starter File I Use for All Projects ⬇️
```editorconfig
root = true

[*]
charset = utf-8
end_of_line = lf
indent_size = 2
indent_style = space
insert_final_newline = true
max_line_length = off
tab_width = 2
trim_trailing_whitespace = true

[*.xml]
indent_size = 4
ij_xml_space_inside_empty_tag = true

[{*.ts,*.tsx}]
ij_html_do_not_indent_children_of_tags = none
ij_html_space_inside_empty_tag = true
ij_typescript_force_quote_style = true
ij_typescript_keep_simple_methods_in_one_line = true
ij_typescript_method_call_chain_wrap = normal
ij_typescript_object_literal_wrap = off
ij_typescript_spaces_within_imports = true
ij_typescript_spaces_within_object_literal_braces = true
ij_typescript_use_double_quotes = false
ij_typescript_var_declaration_wrap = split_into_lines

[{*.js,*.jsx}]
ij_html_do_not_indent_children_of_tags = none
ij_html_space_inside_empty_tag = true
ij_javascript_force_quote_style = true
ij_javascript_keep_simple_methods_in_one_line = true
ij_javascript_method_call_chain_wrap = normal
ij_javascript_object_literal_wrap = off
ij_javascript_spaces_within_imports = true
ij_javascript_spaces_within_object_literal_braces = true
ij_javascript_use_double_quotes = false
ij_javascript_var_declaration_wrap = split_into_lines

[{*.ejs,*.html}]
indent_size = 4
ij_html_attribute_wrap = off
ij_html_do_not_indent_children_of_tags = none
ij_html_space_inside_empty_tag = true
ij_html_text_wrap = off

[*.php]
indent_size = 4
indent_style = tab
ij_php_indent_code_in_php_tags = true
ij_php_method_brace_style = end_of_line
ij_php_new_line_after_php_opening_tag = true

[{*.markdown,*.md}]
ij_markdown_max_lines_around_block_elements = 0
ij_markdown_max_lines_around_header = 0

[*.py]
indent_size = 4
```

[Back to Conventions](https://github.com/mrjackyliang/mrjackyliang/tree/main/conventions)
