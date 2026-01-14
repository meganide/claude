---
name: interview
description: This skill should be used when the user asks to "interview me", "ask me questions about", mentions "spec interview", "interview about spec", or wants to be interviewed in detail about a specification, feature, or implementation.
version: 1.0.0
---

# Interview Skill

Read the SPEC.md file (or any spec file referenced by the user with @) and interview the user in detail using the AskUserQuestion tool about literally anything: technical implementation, UI & UX, concerns, tradeoffs, etc. but make sure the questions are not obvious.

Be very in-depth and continue interviewing the user continually until it's complete, then write the spec to the file.

## Guidelines

1. **Read the spec file first** - Use the file path provided by the user (often with @ reference)
2. **Ask non-obvious questions** - Go beyond surface-level details to uncover:
   - Technical implementation specifics
   - UI & UX considerations
   - Edge cases and error handling
   - Performance and scalability concerns
   - Tradeoffs between different approaches
   - Security implications
   - Testing strategies
   - Deployment considerations
   - Future extensibility

3. **Be thorough** - Continue asking questions until you have a complete understanding of:
   - All technical requirements
   - All user experience requirements
   - All constraints and tradeoffs
   - All edge cases and error scenarios

4. **Use AskUserQuestion tool** - Structure your questions using the tool to get clear, specific answers

5. **Write the complete spec** - Once the interview is complete, write a comprehensive specification to the file that includes all the information gathered
