# Plan Review

When creating any plan (through plan mode or otherwise), run `cursor planname.md` after writing the plan file so the user can review and modify it before proceeding.

# Testing and Verification

**CRITICAL**: All code changes must be thoroughly tested and verified before considering work complete.

## Test Requirements
- **Always write tests** for your work (unit tests, integration tests, or end-to-end tests as appropriate)
- Write tests BEFORE or alongside implementation, not as an afterthought
- Tests should cover happy paths, edge cases, and error conditions
- Ensure test names clearly describe what they're testing

## Verification Process
- **Always run the test suite** after making changes to ensure nothing broke
- Use **chrome-devtools-mcp** to verify UI changes and user flows work correctly
- Manually verify your changes work as expected
- Check for any unintended side effects or regressions
- Never consider work complete until verification is done

## Quality Gates
- All tests must pass before work is considered complete
- No regressions should be introduced
- Changes should be verified both programmatically (tests) and manually (actual usage)

# Code Quality Standards

All code written must adhere to the following software engineering best practices:

## Clean Code Principles
- Code must be clean, readable, and easy to understand
- Use meaningful and descriptive variable, function, and class names
- Keep functions and methods focused and concise
- Write self-documenting code that minimizes the need for comments

## Design Principles
- **Single Responsibility Principle**: Each function, class, or module should have one clear purpose
- **DRY (Don't Repeat Yourself)**: Avoid code duplication; extract common logic into reusable functions
- **Easy to Modify**: Design code to be flexible and adaptable to future changes
- **Easy to Extend**: Use patterns that allow adding new functionality without modifying existing code

## Maintainability
- Prioritize long-term maintainability over short-term convenience
- Write code that other developers (or your future self) can easily understand and modify
- Keep dependencies minimal and well-organized
- Follow established project conventions and patterns consistently

## Software Engineering Best Practices
- Write modular, loosely coupled code
- Handle errors appropriately and predictably
- Consider edge cases and boundary conditions
- Follow language-specific idioms and conventions
- Prefer composition over inheritance where appropriate
- Keep complexity low; favor simple solutions over clever ones
