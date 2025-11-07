# Build/lint/test commands

- `swift test` - Run all tests
- `swift test --filter DateFormatTests` - Run specific test suite
- `swift test --filter "Formats date with year_month_day pattern"` - Run single test
- `swift build` - Build the project
- `swiftformat .` - Format code (configured in .swiftformat)

# Code style guidelines

- Use Swift 6.2 with modern concurrency (async/await, Sendable)
- Prefer protocol-based design with dependency injection for testability
- Use MARK: comments to organize code into logical sections
- Follow naming conventions: camelCase for functions/vars, PascalCase for types
- Use @Sendable annotations for concurrent code
- Prefer Swift Testing framework (@Test, @Suite, #expect)
- Use guard statements for early exits and error handling
- Keep functions small and single-purpose
- Use @unchecked Sendable only when necessary for test mocks
