# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**scmpuff** is a Go CLI tool that adds numbered shortcuts for file paths in common Git commands. It parses `git status` output, assigns numbers to files, and lets users reference files by number (e.g., `git add 1-3`). Supports bash, zsh, fish, and nushell.

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

Two-phase design: (1) `scmpuff status` parses `git status --porcelain -z -b` → numbered display + sets `$e1`, `$e2`, ... env vars. (2) `scmpuff exec`/`expand` resolves numeric args (e.g., `1-3`) back to file paths via those env vars. Shell scripts embedded via `//go:embed`.

### Source Layout (`internal/`)

- **`cmd/`** — Cobra CLI command definitions (one package per subcommand: `status/`, `expand/`, `exec/`, `inits/`, `intro/`, `debug/`, `root.go`)
- **`arguments/`** — Numeric argument parsing and expansion logic
- **`gitstatus/`** — Git status data model; `porcelainv1/` parses `--porcelain` output

### Testing

- **Unit tests** (`*_test.go`): table-driven Go tests
- **Integration tests** (`features/*.feature`): Cucumber/Aruba BDD tests exercising the compiled binary end-to-end

### Detailed Documentation

- [Architecture overview](docs/explanation/architecture-overview.md) — design principles, data flow, technology choices
- [CLI command reference](docs/reference/cli-commands.md) — all commands, flags, and environment variables
- [Development guide](docs/how-to/development.md) — build, test, lint, and common workflows
- [Codebase map](docs/CODEBASE_MAP.md) — module-by-module guide with dependency graphs

## Conventions

- Go 1.24; uses Go modules
- Exit code 128 when not in a git repository (matches git's convention)
- `errcheck` linter is intentionally disabled; `exhaustive` linter is enabled for switch/map completeness
- CGO is disabled for cross-platform builds
- Release builds (goreleaser) use `-mod=readonly` and `-trimpath`; `make build` uses `-mod=readonly` only
