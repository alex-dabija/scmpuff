# Contributing to scmpuff

## Getting Started

1. Fork and clone the repository
2. Set up your development environment (see [development guide](how-to/development.md))
3. Create a feature branch from `main`
4. Make your changes and ensure tests pass
5. Submit a pull request

## Development

For build commands, test instructions, and common development workflows, see the [development guide](how-to/development.md).

**Quick start:**

```bash
make build    # Build binary
make test     # Run unit tests
make lint     # Run linter
make features # Run integration tests (requires Ruby + bundler)
```

If you don't have a local Ruby environment, there is a VS Code [devcontainer](../.devcontainer/devcontainer.json) provided to make things simpler.

## Pull Requests

- Keep changes focused and atomic
- Include tests for new functionality (unit tests in `*_test.go`, integration tests in `features/*.feature`)
- Run `make lint` and `make test` before submitting
- Follow existing code style and conventions
