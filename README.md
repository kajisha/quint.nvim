# quint.nvim

Neovim integration for the [Quint Tree-sitter parser](https://github.com/kajisha/quint-tree-sitter).

## Requirements

- Neovim 0.12.0 or newer
- [`nvim-treesitter`](https://github.com/nvim-treesitter/nvim-treesitter) `main`
- Tree-sitter CLI 0.26.1 or newer
- A C compiler
- `curl`
- `tar`

## Installation

With `lazy.nvim`:

```lua
{
  'kajisha/quint.nvim',
  lazy = false,
  dependencies = {
    {
      'nvim-treesitter/nvim-treesitter',
      branch = 'main',
      lazy = false,
      build = ':TSUpdate',
    },
  },
}
```

Install the released Quint parser explicitly:

```vim
:TSInstall quint
```

Open a `.qnt` file after installation. When this plugin changes its pinned parser
revision, apply the newer parser and queries with:

```vim
:TSUpdate quint
```

To force reinstall the currently pinned parser and queries, use:

```vim
:TSInstall! quint
```

## Troubleshooting

- `No parser for language "quint"`: run `:TSInstall quint` and restart the buffer.
- Compilation failure: verify that Tree-sitter CLI 0.26.1+ and a C compiler are available.
- Missing `nvim-treesitter.parsers`: use the current `nvim-treesitter` `main` branch with Neovim 0.12+.

The parser and highlight queries are pinned to
[`quint-tree-sitter` v0.1.0](https://github.com/kajisha/quint-tree-sitter/releases/tag/v0.1.0).

## License

Apache-2.0. See [LICENSE](LICENSE).
