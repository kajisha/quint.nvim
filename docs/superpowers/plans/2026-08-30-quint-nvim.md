# quint.nvim Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and publish a minimal Neovim plugin that registers, installs, and starts the released Quint Tree-sitter parser.

**Architecture:** A startup plugin registers the `.qnt` filetype and the `quint-tree-sitter` v0.1.0 install specification through the current `nvim-treesitter` `User TSUpdate` API. A filetype plugin starts Tree-sitter without failing the buffer when the parser is missing. The parser repository remains the only owner of highlight queries.

**Tech Stack:** Lua, Neovim 0.12+, `nvim-treesitter` `main`, Tree-sitter CLI 0.26.1+, GitHub Actions, GitHub CLI.

**Spec:** `docs/superpowers/specs/2026-08-30-quint-nvim-design.md`

## Global Constraints

- Support Neovim 0.12.0 or newer and the rewritten `nvim-treesitter` `main` branch only.
- Pin `https://github.com/kajisha/quint-tree-sitter` at release `v0.1.0`.
- Keep highlight queries exclusively in `quint-tree-sitter`; do not copy them into this repository.
- Do not install or update a parser automatically while opening a buffer.
- Do not add a setup API, colorscheme configuration, lualine configuration, personal settings, or compiled parser binaries.
- Use only language-generic fixtures and information from official documentation or `quint-tree-sitter`.
- License the repository under Apache-2.0 and publish it as `github.com/kajisha/quint.nvim` with default branch `main`.

---

### Task 1: Register the Quint filetype and parser source

**Files:**
- Create: `.gitignore`
- Create: `tests/minimal_init.lua`
- Create: `tests/registration.lua`
- Create: `plugin/quint.lua`

**Interfaces:**
- Consumes: Neovim's `vim.filetype.add()` and the current `nvim-treesitter.parsers` module.
- Produces: the `quint` filetype and `require('nvim-treesitter.parsers').quint.install_info` with `url`, `revision`, and `queries` fields.

- [ ] **Step 1: Add the isolated dependency directory and minimal Neovim init**

Create `.gitignore`:

```gitignore
.deps/
```

Create `tests/minimal_init.lua`:

```lua
local root = vim.fn.getcwd()
local treesitter = assert(
  vim.env.NVIM_TREESITTER_DIR,
  'NVIM_TREESITTER_DIR must point to nvim-treesitter'
)

vim.opt.runtimepath:prepend(root)
vim.opt.runtimepath:prepend(treesitter)
vim.cmd('filetype plugin on')
```

- [ ] **Step 2: Write the failing registration test**

Create `tests/registration.lua`:

```lua
vim.api.nvim_exec_autocmds('User', { pattern = 'TSUpdate' })

local parser = assert(
  require('nvim-treesitter.parsers').quint,
  'quint parser is not registered'
)
local install = parser.install_info

assert(install.url == 'https://github.com/kajisha/quint-tree-sitter')
assert(install.revision == 'v0.1.0')
assert(install.queries == 'queries')

local path = vim.fn.tempname() .. '.qnt'
vim.fn.writefile({ 'module Example {}' }, path)
vim.cmd.edit(vim.fn.fnameescape(path))

assert(vim.bo.filetype == 'quint', 'expected .qnt filetype to be quint')

vim.fn.delete(path)
print('OK parser-registration filetype=quint revision=v0.1.0')
vim.cmd('qa!')
```

- [ ] **Step 3: Install the test dependency and verify RED**

Run:

```bash
git clone --depth 1 https://github.com/nvim-treesitter/nvim-treesitter .deps/nvim-treesitter
NVIM_TREESITTER_DIR="$PWD/.deps/nvim-treesitter" \
  nvim --headless -u tests/minimal_init.lua -l tests/registration.lua
```

Expected: exit non-zero with `quint parser is not registered` because `plugin/quint.lua` does not exist.

- [ ] **Step 4: Implement the startup plugin**

Create `plugin/quint.lua`:

```lua
if vim.g.loaded_quint_nvim then
  return
end
vim.g.loaded_quint_nvim = 1

vim.filetype.add {
  extension = {
    qnt = 'quint',
  },
}

vim.api.nvim_create_autocmd('User', {
  group = vim.api.nvim_create_augroup('quint-nvim-parser', { clear = true }),
  pattern = 'TSUpdate',
  callback = function()
    require('nvim-treesitter.parsers').quint = {
      install_info = {
        url = 'https://github.com/kajisha/quint-tree-sitter',
        revision = 'v0.1.0',
        queries = 'queries',
      },
    }
  end,
})
```

- [ ] **Step 5: Verify GREEN and commit**

Run:

```bash
NVIM_TREESITTER_DIR="$PWD/.deps/nvim-treesitter" \
  nvim --headless -u tests/minimal_init.lua -l tests/registration.lua
git diff --check
```

Expected: exit zero and `OK parser-registration filetype=quint revision=v0.1.0`.

Commit:

```bash
git add .gitignore tests/minimal_init.lua tests/registration.lua plugin/quint.lua
git commit -m "feat: register the Quint parser"
```

---

### Task 2: Start highlighting and verify the released parser end to end

**Files:**
- Create: `ftplugin/quint.lua`
- Create: `tests/integration.lua`

**Interfaces:**
- Consumes: the parser registration from Task 1 and `require('nvim-treesitter').install()`.
- Produces: automatic `vim.treesitter.start(0, 'quint')` for Quint buffers and a headless acceptance test for the v0.1.0 parser/query bundle.

- [ ] **Step 1: Write the failing integration test**

Create `tests/integration.lua`:

```lua
vim.api.nvim_exec_autocmds('User', { pattern = 'TSUpdate' })

assert(
  require('nvim-treesitter').install('quint', { force = true }):wait(300000),
  'failed to install the Quint parser'
)

local path = vim.fn.tempname() .. '.qnt'
vim.fn.writefile({
  'module Example {',
  '  type Status = | Ready | Waiting',
  '  var id: int',
  "  action step = id' = id + 1",
  '  val record = Set({ primary: Ready })',
  '}',
}, path)
vim.cmd.edit(vim.fn.fnameescape(path))

assert(vim.bo.filetype == 'quint')
assert(vim.b.did_quint_ftplugin == 1, 'Quint ftplugin did not run')

local parser = vim.treesitter.get_parser(0, 'quint')
local tree = assert(parser:parse()[1], 'Quint parser returned no tree')
assert(not tree:root():has_error(), tree:root():sexpr())

local expected = {
  { 0, 0, 'keyword' },
  { 0, 7, 'module' },
  { 1, 2, 'keyword' },
  { 1, 7, 'type' },
  { 1, 18, 'constructor' },
  { 2, 2, 'keyword' },
  { 2, 6, 'variable' },
  { 2, 10, 'type.builtin' },
  { 3, 16, 'variable' },
  { 3, 18, 'operator' },
  { 3, 20, 'operator' },
  { 3, 22, 'variable' },
  { 3, 25, 'operator' },
  { 3, 27, 'number' },
  { 4, 15, 'function' },
  { 4, 29, 'constructor' },
}

for _, item in ipairs(expected) do
  local row, col, wanted = item[1], item[2], item[3]
  local found = false
  local names = {}

  for _, capture in ipairs(vim.treesitter.get_captures_at_pos(0, row, col)) do
    names[#names + 1] = capture.capture
    found = found or capture.capture == wanted
  end

  assert(
    found,
    string.format('%d:%d expected @%s, got [%s]', row + 1, col, wanted, table.concat(names, ', '))
  )
end

vim.fn.delete(path)
print(string.format('OK quint-integration root=%s captures=%d', tree:root():type(), #expected))
vim.cmd('qa!')
```

- [ ] **Step 2: Verify RED in an isolated Neovim data directory**

Run:

```bash
test_root="$(mktemp -d)"
XDG_DATA_HOME="$test_root/data" \
XDG_STATE_HOME="$test_root/state" \
XDG_CACHE_HOME="$test_root/cache" \
NVIM_TREESITTER_DIR="$PWD/.deps/nvim-treesitter" \
  nvim --headless -u tests/minimal_init.lua -l tests/integration.lua
```

Expected: exit non-zero with `Quint ftplugin did not run` because `ftplugin/quint.lua` does not exist. Parser installation may complete before this assertion.

- [ ] **Step 3: Implement the filetype plugin**

Create `ftplugin/quint.lua`:

```lua
if vim.b.did_quint_ftplugin then
  return
end
vim.b.did_quint_ftplugin = 1

pcall(vim.treesitter.start, 0, 'quint')
```

- [ ] **Step 4: Verify GREEN and commit**

Run the isolated command from Step 2 again.

Expected: exit zero and `OK quint-integration root=source_file captures=16`.

Then run the registration test again:

```bash
NVIM_TREESITTER_DIR="$PWD/.deps/nvim-treesitter" \
  nvim --headless -u tests/minimal_init.lua -l tests/registration.lua
git diff --check
```

Commit:

```bash
git add ftplugin/quint.lua tests/integration.lua
git commit -m "feat: start Quint Tree-sitter highlighting"
```

---

### Task 3: Add public documentation, license, and continuous integration

**Files:**
- Create: `README.md`
- Create: `LICENSE`
- Create: `.github/workflows/ci.yml`

**Interfaces:**
- Consumes: the commands and compatibility contract verified by Tasks 1 and 2.
- Produces: installation guidance, Apache-2.0 licensing, and an isolated Ubuntu CI run of both headless tests.

- [ ] **Step 1: Write the README**

Create `README.md` with this content:

````markdown
# quint.nvim

Neovim integration for the [Quint Tree-sitter parser](https://github.com/kajisha/quint-tree-sitter).

## Requirements

- Neovim 0.12.0 or newer
- [`nvim-treesitter`](https://github.com/nvim-treesitter/nvim-treesitter) `main`
- Tree-sitter CLI 0.26.1 or newer
- A C compiler

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

Open a `.qnt` file after installation. To reinstall the pinned parser and its queries:

```vim
:TSUpdate quint
```

## Troubleshooting

- `No parser for language "quint"`: run `:TSInstall quint` and restart the buffer.
- Compilation failure: verify that Tree-sitter CLI 0.26.1+ and a C compiler are available.
- Missing `nvim-treesitter.parsers`: use the current `nvim-treesitter` `main` branch with Neovim 0.12+.

The parser and highlight queries are pinned to
[`quint-tree-sitter` v0.1.0](https://github.com/kajisha/quint-tree-sitter/releases/tag/v0.1.0).

## License

Apache-2.0. See [LICENSE](LICENSE).
````

- [ ] **Step 2: Add the canonical Apache-2.0 license**

Run:

```bash
curl --fail --silent --show-error --location \
  https://raw.githubusercontent.com/kajisha/quint-tree-sitter/v0.1.0/LICENSE \
  --output LICENSE
```

Verify that `LICENSE` begins with `Apache License` and contains `Version 2.0, January 2004`.

- [ ] **Step 3: Add the CI workflow**

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
  pull_request:

permissions:
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: rhysd/action-setup-vim@v1
        with:
          version: v0.12.0
          neovim: true
      - uses: actions/setup-node@v4
        with:
          node-version: 22
      - name: Install Tree-sitter CLI
        run: npm install --global tree-sitter-cli@0.26.1
      - name: Fetch nvim-treesitter
        run: git clone --depth 1 https://github.com/nvim-treesitter/nvim-treesitter .deps/nvim-treesitter
      - name: Test parser registration
        env:
          NVIM_TREESITTER_DIR: ${{ github.workspace }}/.deps/nvim-treesitter
        run: nvim --headless -u tests/minimal_init.lua -l tests/registration.lua
      - name: Test Quint integration
        env:
          NVIM_TREESITTER_DIR: ${{ github.workspace }}/.deps/nvim-treesitter
          XDG_DATA_HOME: ${{ runner.temp }}/nvim-data
          XDG_STATE_HOME: ${{ runner.temp }}/nvim-state
          XDG_CACHE_HOME: ${{ runner.temp }}/nvim-cache
        run: nvim --headless -u tests/minimal_init.lua -l tests/integration.lua
```

- [ ] **Step 4: Run both tests and inspect repository boundaries**

Run:

```bash
NVIM_TREESITTER_DIR="$PWD/.deps/nvim-treesitter" \
  nvim --headless -u tests/minimal_init.lua -l tests/registration.lua

test_root="$(mktemp -d)"
XDG_DATA_HOME="$test_root/data" \
XDG_STATE_HOME="$test_root/state" \
XDG_CACHE_HOME="$test_root/cache" \
NVIM_TREESITTER_DIR="$PWD/.deps/nvim-treesitter" \
  nvim --headless -u tests/minimal_init.lua -l tests/integration.lua

rg -n '/Users/|colorscheme|lualine' --glob '!docs/superpowers/**' .
git diff --check
```

Expected: both Neovim commands exit zero; the boundary scan returns no matches; `git diff --check` exits zero.

- [ ] **Step 5: Commit documentation and CI**

```bash
git add README.md LICENSE .github/workflows/ci.yml
git commit -m "docs: document installation and add CI"
```

---

### Task 4: Publish the public GitHub repository and verify CI

**Files:**
- No file changes.

**Interfaces:**
- Consumes: a clean, fully tested local `main` branch from Tasks 1 through 3 and authenticated GitHub CLI access for `kajisha`.
- Produces: public repository `https://github.com/kajisha/quint.nvim`, SSH `origin`, pushed `main`, and a successful GitHub Actions run.

- [ ] **Step 1: Run the final local verification gate**

Run both Neovim commands and the boundary scan from Task 3 Step 4, then run:

```bash
git status --short
git log --oneline --decorate -5
gh repo view kajisha/quint.nvim --json nameWithOwner,visibility,url
```

Expected: tests exit zero, boundary scan has no matches, worktree output is empty, and `gh repo view` reports that the repository does not yet exist.

- [ ] **Step 2: Create and push the repository**

Run:

```bash
gh repo create kajisha/quint.nvim \
  --public \
  --source=. \
  --remote=origin \
  --push \
  --description='Neovim integration for the Quint Tree-sitter parser'
```

- [ ] **Step 3: Verify ownership, visibility, branch, remote, and commit identity**

Run:

```bash
gh repo view kajisha/quint.nvim \
  --json nameWithOwner,visibility,url,defaultBranchRef
git remote -v
git rev-parse HEAD
git ls-remote origin refs/heads/main
```

Expected: owner/name `kajisha/quint.nvim`, visibility `PUBLIC`, default branch `main`, SSH `origin`, and identical local/remote commit SHAs.

- [ ] **Step 4: Wait for and verify GitHub Actions**

Run:

```bash
run_id="$(gh run list --repo kajisha/quint.nvim --workflow CI --limit 1 --json databaseId --jq '.[0].databaseId')"
gh run watch "$run_id" --repo kajisha/quint.nvim --exit-status
gh run view "$run_id" --repo kajisha/quint.nvim --json status,conclusion,url,headSha
```

Expected: `status` is `completed`, `conclusion` is `success`, and `headSha` equals local `HEAD`.
