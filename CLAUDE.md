# Code Quality
- Maintainable production code
- Clean, readable code with meaningful names
- Focused, concise functions
- Self-documenting, minimal comments
- Single Responsibility Principle
- DRY - no duplication, extract common logic
- Easy to modify and extend
- Modular, loosely coupled
- Handle errors appropriately
- Consider edge cases
- Follow language idioms
- If tests that previously passed now fail (regression), investigate and fix the issue
- Prefer composition over inheritance
- Keep complexity low, favor simple solutions

# Testing
- Always run `npm test` before finishing work (if that doesn't work, check package.json for the correct test command)
- Never commit code with failing tests
- If your changes break existing tests, reconsider your approach or fix the underlying issue
- Do not modify tests just to make them pass - fix the actual code causing the failure
- Exception: only modify tests if the test itself is incorrect or outdated
