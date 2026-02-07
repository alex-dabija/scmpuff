# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**scmpuff** is a Go CLI tool that adds numbered shortcuts for file paths in common Git commands. It parses `git status` output, assigns numbers to files, and lets users reference files by number (e.g., `git add 1-3`). Supports bash, zsh, and fish shells.

## Build & Development Commands

```bash
make build              # Build binary to bin/scmpuff (injects version via ldflags)
make test               # Run Go unit tests (go test ./...)
make lint               # Run golangci-lint (v2, config in .golangci.yml)
make features           # Run Cucumber integration tests (requires: bundle install, build)
make features-wip       # Run only @wip-tagged integration tests
make package            # Build release packages via goreleaser
make clean              # Remove tmp/ (aruba test artifacts)
make clobber            # Remove dist/ and bin/scmpuff
```

**Running a single unit test:**
```bash
go test ./internal/arguments/ -run TestExpandArgs
```

**Running a single integration test:**
```bash
bundle exec cucumber features/command_status.feature
```

**Integration test prerequisites:** Ruby with bundler, `bundle install`, plus zsh and fish installed for full shell coverage.

## Architecture

### Source Layout (`internal/`)

- **`cmd/`** — Cobra CLI command definitions, one package per subcommand:
  - `status/` — Main feature: numbered `git status` display with env var export
  - `expand/` — Expands numeric shortcuts (e.g., "1-3") to file paths from env vars
  - `exec/` — Runs a command with numeric args expanded inline
  - `inits/` — Generates shell initialization scripts (embeds shell code via `//go:embed`)
  - `intro/` — Intro/help display
  - `debug/` — Debug dump utilities
  - `root.go` — Root command wiring
- **`arguments/`** — Core logic for parsing and expanding numeric file arguments
- **`gitstatus/`** — Git status parsing; `porcelainv1/` handles `git status --porcelain` output

### Key Data Flow

```
git status --porcelain -z -b
  → porcelainv1.Process() → gitstatus.StatusInfo
  → status.Renderer (colored terminal output + sets $e1, $e2, ... env vars)
```

Users then reference files as `1`, `2`, `1-3`, etc. The `expand` and `exec` commands resolve these numbers back to file paths via the `$eN` environment variables.

### Shell Integration

Shell scripts are embedded in the binary via `//go:embed` directives in `internal/cmd/inits/`. The `scmpuff init` command outputs these scripts for users to `eval` in their shell config. Scripts provide:
- `scmpuff_status` shell function (wraps `git status` with numbered output)
- Git command wrappers (add, checkout, diff, reset) that auto-expand numeric args

### Testing

- **Unit tests** (`*_test.go`): Standard Go tests, table-driven pattern used extensively
- **Integration tests** (`features/*.feature`): Cucumber/Aruba BDD tests that exercise the compiled binary end-to-end, testing shell integration, edge cases (symlinks, special characters, merge conflicts, renames)

## Conventions

- Go 1.24; uses Go modules
- Exit code 128 when not in a git repository (matches git's convention)
- `errcheck` linter is intentionally disabled; `exhaustive` linter is enabled for switch/map completeness
- CGO is disabled for cross-platform builds
- Build uses `-mod=readonly` and `-trimpath`
