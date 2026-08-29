# quint.nvim Design

## Purpose

`quint.nvim` is a small Neovim plugin that makes the Quint parser from
[`kajisha/quint-tree-sitter`](https://github.com/kajisha/quint-tree-sitter)
available through the current `nvim-treesitter` custom-language API. It
registers `.qnt` files, registers the released parser source, and starts
Tree-sitter highlighting for Quint buffers.

The first release targets Neovim 0.12 or newer and the rewritten
`nvim-treesitter` `main` branch. It does not support the legacy
`get_parser_configs()` API from the former `master` branch.

## User Experience

A user installs `quint.nvim` together with `nvim-treesitter`, runs
`:TSInstall quint`, and opens a `.qnt` file. Neovim assigns the `quint`
filetype and starts Tree-sitter highlighting with the queries shipped by
`quint-tree-sitter` v0.1.0.

The plugin does not install or update parsers during buffer opening. Parser
installation is an explicit user action because it downloads source and runs
a compiler.

## Architecture

### Plugin Loader

`plugin/quint.lua` has two responsibilities:

1. Register `.qnt` as the `quint` filetype with `vim.filetype.add()`.
2. Register the `quint` parser inside a `User TSUpdate` autocmd using
   `require('nvim-treesitter.parsers').quint`.

The parser install specification uses:

- URL: `https://github.com/kajisha/quint-tree-sitter`
- Revision: `v0.1.0`
- Query directory: `queries`

The parser name and filetype are both `quint`, so
`vim.treesitter.language.register()` is unnecessary.

### Filetype Plugin

`ftplugin/quint.lua` calls `vim.treesitter.start(0, 'quint')` through
`pcall`. A missing parser therefore leaves the buffer usable without an
uncaught startup error. The README explains that `:TSInstall quint` is the
remedy.

### Query Ownership

Highlight queries remain exclusively in `quint-tree-sitter`. `quint.nvim`
does not vendor `queries/quint/highlights.scm` or copy the parser query into
its own runtime. This avoids two independently versioned copies of the same
capture definitions.

`quint.nvim` pins the parser release instead of following a moving branch.
Updating the parser requires a reviewed change to the pinned release.

## Repository Layout

```text
quint.nvim/
├── .github/workflows/ci.yml
├── docs/superpowers/specs/2026-08-30-quint-nvim-design.md
├── ftplugin/quint.lua
├── plugin/quint.lua
├── tests/integration.lua
├── tests/minimal_init.lua
├── LICENSE
└── README.md
```

Each runtime file has one responsibility. There is no setup API in v0.1.0
because the parser URL, released revision, language name, and file extension
are invariants rather than user preferences.

## Dependencies and Compatibility

- Neovim 0.12.0 or newer.
- `nvim-treesitter` from its current `main` branch, loaded eagerly as required
  by its documentation.
- `tree-sitter-cli` 0.26.1 or newer and a C compiler when installing the
  parser.
- `quint-tree-sitter` release v0.1.0.

These requirements follow the current official
[`nvim-treesitter` README](https://github.com/nvim-treesitter/nvim-treesitter/blob/main/README.md)
and Neovim's
[`treesitter` documentation](https://neovim.io/doc/user/treesitter.html).

## Testing

The headless integration test uses a generic Quint module created in a
temporary file. It verifies:

- `.qnt` resolves to the `quint` filetype.
- the custom parser registration points to the v0.1.0 release.
- the parser installs and produces an error-free syntax tree.
- representative `@keyword`, `@module`, `@type`, `@constructor`, `@variable`,
  and `@operator` captures are available.

The fixture contains only language-generic names. Tests and documentation
must not use information taken from unrelated repositories or projects.

GitHub Actions runs the same headless test on Ubuntu with an isolated Neovim
data directory so a previously installed local parser cannot make the test
pass accidentally.

## Documentation

The README contains:

- compatibility requirements;
- a `lazy.nvim` installation example;
- the explicit `:TSInstall quint` and `:TSUpdate quint` commands;
- a minimal troubleshooting section for a missing compiler, missing parser,
  or unsupported Neovim/nvim-treesitter version;
- links to the Quint parser release and official Neovim/nvim-treesitter
  documentation.

It does not recommend a colorscheme or contain personal Neovim settings.

## Distribution

The repository is public at `github.com/kajisha/quint.nvim`, uses the
Apache-2.0 license to match `quint-tree-sitter`, and uses `main` as its default
branch.

## Alternatives Considered

### Vendor the highlight query in quint.nvim

This would let Neovim discover the query independently of parser installation,
but every parser release would require synchronizing two copies. The added
drift risk is not justified for the first release.

### Provide only a README configuration snippet

This avoids plugin runtime code but gives users no reusable parser registration
or filetype integration. It does not meet the goal of a dedicated Neovim
plugin.

### Bundle compiled parser binaries

This removes the local compiler requirement but introduces OS and CPU build
matrices, release assets, and binary provenance work. Source compilation via
`nvim-treesitter` is simpler and consistent with its supported workflow.

## Acceptance Criteria

- A clean Neovim 0.12+ environment can install the plugin and run
  `:TSInstall quint` successfully.
- Opening a generic `.qnt` fixture starts an error-free Quint syntax tree and
  exposes the expected highlight captures.
- The plugin references `quint-tree-sitter` v0.1.0 rather than a moving branch.
- The repository contains no copied highlight query, colorscheme configuration,
  personal settings, or unrelated project information.
- The headless integration test and GitHub Actions workflow pass.
