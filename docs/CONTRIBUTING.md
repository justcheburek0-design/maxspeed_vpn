# Contributing to MaxSpeedVPN

Thank you for your interest in contributing to MaxSpeedVPN! This document provides guidelines for contributing to the project.

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Respect different viewpoints and experiences

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported
2. Create a new issue with a clear title and description
3. Include steps to reproduce the bug
4. Include your device info and app version
5. Attach screenshots or logs if applicable

### Suggesting Features

1. Check if the feature has already been suggested
2. Create a new issue with a clear title and description
3. Explain the use case and expected behavior
4. Consider the impact on existing functionality

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Write or update tests
5. Ensure all tests pass: `flutter test`
6. Ensure code is formatted: `flutter format .`
7. Ensure no analysis issues: `flutter analyze`
8. Commit with clear messages
9. Push to your fork
10. Create a pull request

## Development Setup

1. Follow the [Setup Guide](SETUP.md) to set up your development environment
2. Create a branch for your changes
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Coding Standards

### Dart Code

- Follow the [Dart Style Guide](https://dart.dev/effective-dart/style)
- Use `flutter format .` to format code
- Use meaningful variable and function names
- Add documentation comments for public APIs
- Keep functions small and focused
- Use `const` constructors where possible

### File Organization

```
lib/
  core/           # Core utilities, constants, errors, theme
  data/           # Models, repositories, data sources
  domain/         # Entities, use cases, repository interfaces
  presentation/   # Screens, widgets, providers, theme
```

### Naming Conventions

- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Functions**: `camelCase`
- **Variables**: `camelCase`
- **Constants**: `camelCase` (or `SCREAMING_SNAKE_CASE` for true constants)
- **Private members**: `_prefixedWithUnderscore`

### Testing

- Write unit tests for all use cases
- Write widget tests for all screens
- Write integration tests for critical flows
- Aim for >80% code coverage

## Commit Messages

Use clear, descriptive commit messages:

```
feat: add VLESS Reality support
fix: resolve connection timeout issue
docs: update API documentation
refactor: simplify server parsing logic
test: add tests for subscription parser
```

## Review Process

1. All changes require at least one review
2. Address review comments promptly
3. Keep pull requests focused and small
4. Rebase on main before merging

## License

By contributing to MaxSpeedVPN, you agree that your contributions will be licensed under the GPL-3.0 License.
