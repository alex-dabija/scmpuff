# How to Develop scmpuff

## Prerequisites

- **Go 1.24+** — for building and unit testing
- **Ruby + Bundler** — for integration tests (Cucumber/Aruba)
- **zsh, fish, and nushell** — for full shell integration test coverage

If you don't have a local Ruby environment, there is a [VS Code devcontainer](../../.devcontainer/devcontainer.json) that provides everything pre-configured.

## Build

```bash
make build
```

Builds the binary to `bin/scmpuff`, injecting the current git tag as the version via ldflags.

## Run Tests

### Unit tests

```bash
make test                                        # All unit tests
go test ./internal/arguments/ -run TestExpandArgs # Single test
```

### Integration tests

```bash
bundle install              # One-time setup
make features               # All integration tests
make features-wip           # Only @wip-tagged tests
bundle exec cucumber features/command_status.feature  # Single feature file
```

### Lint

```bash
make lint
```

Uses [golangci-lint](https://golangci-lint.run/) with config in `.golangci.yml`. Note: `errcheck` is intentionally disabled; `exhaustive` is enabled for switch/map completeness.

## Common Development Tasks

### Add a new git subcommand wrapper

Edit the shell wrapper scripts that are embedded in the binary:

1. `internal/cmd/inits/data/git_wrapper.sh` — bash/zsh wrapper
2. `internal/cmd/inits/data/git_wrapper.fish` — fish wrapper
3. `internal/cmd/inits/data/git_wrapper.nu` — nushell wrapper

Add the command to the appropriate category (absolute-path or relative-path expansion).

### Add a new CLI subcommand

1. Create a new package under `internal/cmd/`
2. Implement `NewXxxCmd() *cobra.Command`
3. Wire it in `internal/cmd/root.go`

### Modify status display formatting

1. Edit `internal/cmd/status/render.go`
2. Regenerate golden files: `go test ./internal/cmd/status/ -update`
3. Review the updated `.golden` files in `internal/cmd/status/testdata/`

### Add a new git status change type

1. Add to `ChangeType` enum in `internal/gitstatus/gitstatus.go`
2. Update the `changeTypeData` map
3. Update XY code mapping in `internal/gitstatus/porcelainv1/process.go`

### Add integration tests

Add scenarios to `features/*.feature`, using step definitions from `features/step_definitions/scmpuff_steps.rb`.

## Release

```bash
make package    # Build release packages via goreleaser (local only)
```

Actual releases are triggered by pushing a git tag, which runs the `release.yml` GitHub Actions workflow using goreleaser. Builds target Linux, macOS, and Windows across amd64, arm, and arm64.
