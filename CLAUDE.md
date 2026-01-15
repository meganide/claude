# Plan Review
Run `cursor planname.md` after writing plan files for review.

# Testing & Verification
**CRITICAL**: Test and verify all changes before completion.

- Write tests BEFORE/alongside implementation (unit/integration/e2e)
- Cover happy paths, edge cases, errors
- Clear test names describing what's tested
- Always run test suite after changes
- Manually verify + check for regressions
- All tests must pass, no regressions allowed

# Code Quality
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
- Prefer composition over inheritance
- Keep complexity low, favor simple solutions
