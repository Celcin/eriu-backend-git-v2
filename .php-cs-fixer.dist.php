<?php

/*
 * PHP-CS-Fixer Configuration
 * Enforces consistent code style across the project
 * Brace style: Allman (braces on their own line)
 */

$finder = (new PhpCsFixer\Finder())
	->in(__DIR__)
	->exclude([
		'var',
		'vendor',
		'node_modules',
		'.git',
	])
	->notPath([
		'config/bundles.php',
		'config/preload.php',
		'public/index.php',
	])
	->name('*.php')
;

return (new PhpCsFixer\Config())
	->setRiskyAllowed(true)
	->setIndent("\t")
	->setLineEnding("\n")
	->setFinder($finder)
	->setRules([
		// Base ruleset
		'@PSR12' => true,

		// Override: Allman brace style (braces on own line)
		'braces_position' => [
			'allow_single_line_anonymous_functions' => false,
			'allow_single_line_empty_anonymous_classes' => false,
			'anonymous_classes_opening_brace' => 'next_line_unless_newline_at_signature_end',
			'anonymous_functions_opening_brace' => 'next_line_unless_newline_at_signature_end',
			'classes_opening_brace' => 'next_line_unless_newline_at_signature_end',
			'control_structures_opening_brace' => 'next_line_unless_newline_at_signature_end',
			'functions_opening_brace' => 'next_line_unless_newline_at_signature_end',
		],

		// else/catch/finally on next line
		'control_structure_continuation_position' => [
			'position' => 'next_line',
		],

		// Blank line after opening tag
		'blank_line_after_opening_tag' => true,
		'blank_lines_before_namespace' => [
			'min_line_breaks' => 2,
			'max_line_breaks' => 2,
		],

		// Control structure braces
		'control_structure_braces' => true,

		// Blank lines before certain statements
		'blank_line_before_statement' => [
			'statements' => [
				'return',
				'throw',
				'try',
				'foreach',
				'for',
				'while',
				'do',
				'switch',
				'if',
			],
		],

		// Allow blank line after class opening brace
		'no_blank_lines_after_class_opening' => false,

		// Statement indentation
		'statement_indentation' => true,

		// Array syntax
		'array_syntax' => ['syntax' => 'short'],

		// Spacing
		'concat_space' => ['spacing' => 'one'],
		'binary_operator_spaces' => [
			'default' => 'single_space',
		],

		// No extra blank lines
		'no_extra_blank_lines' => [
			'tokens' => [
				'curly_brace_block',
				'extra',
				'parenthesis_brace_block',
				'square_brace_block',
				'use',
			],
		],

		// Comments
		'single_line_comment_style' => [
			'comment_types' => ['hash'],
		],

		// Imports
		'ordered_imports' => [
			'sort_algorithm' => 'alpha',
			'imports_order' => ['const', 'class', 'function'],
		],
		'no_unused_imports' => true,
		'single_import_per_statement' => true,

		// PHP features
		'declare_strict_types' => false,
		'void_return' => true,
		'nullable_type_declaration_for_default_null_value' => true,

		// Whitespace
		'no_trailing_whitespace' => true,
		'no_trailing_whitespace_in_comment' => true,
		'single_blank_line_at_eof' => true,
		'no_whitespace_in_blank_line' => true,

		// PHPDoc
		'phpdoc_align' => [
			'align' => 'left',
		],
		'phpdoc_indent' => true,
		'phpdoc_scalar' => true,
		'phpdoc_separation' => false,
		'phpdoc_single_line_var_spacing' => true,
		'phpdoc_trim' => true,
		'phpdoc_types' => true,
		'phpdoc_var_without_name' => false,
		'no_empty_phpdoc' => true,

		// Method and function
		'method_argument_space' => [
			'on_multiline' => 'ensure_fully_multiline',
		],
		'function_declaration' => [
			'closure_function_spacing' => 'one',
			'closure_fn_spacing' => 'one',
		],

		// Visibility / modifier keywords
		'modifier_keywords' => [
			'elements' => ['property', 'method', 'const'],
		],

		// Class attributes
		'class_attributes_separation' => [
			'elements' => [
				'const' => 'none',
				'property' => 'none',
				'method' => 'one',
				'trait_import' => 'none',
			],
		],

		// Semicolons
		'no_empty_statement' => true,
		'multiline_whitespace_before_semicolons' => [
			'strategy' => 'no_multi_line',
		],

		// Encoding
		'encoding' => true,
		'full_opening_tag' => true,
	])
;