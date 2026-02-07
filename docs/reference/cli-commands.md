# CLI Command Reference

## `scmpuff status`

Displays a numbered `git status` output with environment variable export.

```
scmpuff status [flags]
```

| Flag | Short | Description |
|------|-------|-------------|
| `--filelist` | `-f` | Include machine-parseable tab-delimited file list as first output line |
| `--display` | | Control display output |

**Behavior**:
- Runs `git status --porcelain -z -b` internally
- Assigns sequential numbers to each changed file
- Outputs colored, grouped display (Staged → Unmerged → Unstaged → Untracked)
- With `-f`, first line contains tab-delimited file paths for shell parsing
- Exit code 128 when not in a git repository

## `scmpuff exec`

Executes a command with numeric arguments expanded to file paths.

```
scmpuff exec [flags] -- <command> [args...]
```

| Flag | Short | Description |
|------|-------|-------------|
| `--relative` | `-r` | Expand to relative paths instead of absolute |

**Behavior**:
- Replaces numeric arguments (e.g., `1`, `2-4`) with file paths from `$eN` environment variables
- Passes through stdin/stdout/stderr to the subprocess
- Preserves the subprocess exit code

## `scmpuff expand`

Expands numeric arguments to shell-escaped file paths.

```
scmpuff expand [flags] [args...]
```

| Flag | Short | Description |
|------|-------|-------------|
| `--relative` | `-r` | Expand to relative paths instead of absolute |

**Behavior**:
- Resolves numeric arguments to file paths from `$eN` environment variables
- Outputs tab-delimited, shell-escaped paths
- Unlike `exec`, does not run a command — outputs for shell consumption

## `scmpuff init`

Outputs shell initialization scripts for eval in shell config.

```
scmpuff init [flags]
```

| Flag | Short | Description |
|------|-------|-------------|
| `--shell` | `-s` | Shell type: `sh`, `bash`, `zsh`, or `fish` |
| `--aliases` | `-a` | Include short aliases (gs, ga, gd, etc.) |
| `--wrap` | `-w` | Include git command wrapper |

**Behavior**:
- Auto-detects shell type from `$SHELL` if not specified
- Outputs shell functions: `scmpuff_status`, `scmpuff_clear_vars`, and optionally a `git` wrapper
- Designed to be used with `eval`:
  - bash/zsh: `eval "$(scmpuff init -s)"`
  - fish: `scmpuff init --shell=fish | source`

## Shell Functions (provided by `scmpuff init`)

| Function | Alias | Description |
|----------|-------|-------------|
| `scmpuff_status` | `gs` | Runs `scmpuff status --filelist` and exports `$eN` vars |
| `scmpuff_clear_vars` | — | Unsets `$e1` through `$e999` |
| `git` (wrapper) | — | Intercepts git commands, auto-expands numeric args |

### Git Wrapper Command Categories

| Category | Commands | Expansion Mode |
|----------|----------|---------------|
| Absolute paths | `commit`, `blame`, `log`, `rebase`, `merge` | `scmpuff exec` |
| Relative paths | `checkout`, `diff`, `rm`, `reset`, `restore` | `scmpuff exec -r` |
| Special | `add` | Expand + auto-refresh status after |
| Passthrough | All others | Direct to git (no expansion) |

### Default Aliases

| Alias | Expands To |
|-------|-----------|
| `gs` | `scmpuff_status` |
| `ga` | `git add` |
| `gd` | `git diff` |
| `gco` | `git checkout` |

## `scmpuff debug dump`

Hidden command for generating bug report data.

```
scmpuff debug dump
```

**Behavior**: Collects environment info and porcelain output samples into a ZIP archive for bug reports.

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `$e1`, `$e2`, ... | File paths set by `scmpuff_status`, used by `exec`/`expand` |
| `$SCMPUFF_GIT_CMD` | Override the git binary path (default: auto-detected from `$PATH`) |
