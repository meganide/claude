---
name: interview
description: This skill should be used when the user asks to "interview me", "ask me questions about", mentions "spec interview", "interview about spec", or wants to be interviewed in detail about a specification, feature, or implementation.
version: 1.1.0
---

# Interview Skill

Read the SPEC.md file (or any spec file referenced by the user with @) and interview the user in detail using the AskUserQuestion tool about literally anything: technical implementation, UI & UX, concerns, tradeoffs, etc. but make sure the questions are not obvious.

Be very in-depth and continue interviewing the user continually until it's complete, then write the spec to the file.

## Output Location

**IMPORTANT**: Always save the completed spec to the `specs/` folder in the project root with a unique filename:

- **Format**: `specs/{slug}-{timestamp}.md`
- **Slug**: Auto-generate a kebab-case slug from the main feature/topic name (e.g., `user-authentication`, `payment-integration`, `dashboard-redesign`)
- **Timestamp**: ISO 8601 format date-time (e.g., `2025-01-19T14-30-00`)
- **Example**: `specs/user-authentication-2025-01-19T14-30-00.md`

Create the `specs/` directory if it doesn't exist. Derive the slug automatically from the feature being discussed - do not ask the user for it.

## Guidelines

1. **Read the spec file first** - Use the file path provided by the user (often with @ reference), if any
2. **Ask non-obvious questions** - Go beyond surface-level details to uncover:
   - Technical implementation specifics
   - Architecture and architectural changes (component structure, design patterns, system design)
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

5. **Write the complete spec** - Once the interview is complete, write a comprehensive specification to the file that includes:
   - All the information gathered from the interview
   - **Detailed code implementations** - Include specific code examples, function signatures, class structures, and implementation details
   - **Database schema changes** - If the feature requires database modifications, include:
     - Table structures with field types and constraints
     - Indexes and relationships
     - Migration strategies
     - Data migration considerations
   - **Detailed tasks breakdown** - Create a comprehensive task list using checkbox format. Each task should follow this structure:
     ```
     [ ] Task title (e.g., "Add authentication")
         - Detailed implementation notes
         - Code snippet implementation (actual code to be written)
         - Files that need to be modified or created
         - Dependencies on other tasks
         - Testing requirements for that specific task
         - Acceptance criteria
     ```

     Example:
     ```
     [ ] Add authentication
         - Implement JWT-based authentication with refresh tokens
         - Code implementation:
           ```typescript
           // src/services/auth.ts
           export class AuthService {
             async login(email: string, password: string): Promise<{ token: string, refreshToken: string }> {
               const user = await this.validateCredentials(email, password);
               const token = this.generateToken(user);
               const refreshToken = this.generateRefreshToken(user);
               return { token, refreshToken };
             }
           }
           ```
         - Files: src/services/auth.ts, src/routes/auth.ts, src/middleware/authenticate.ts
         - Dependencies: Database schema changes must be completed first
         - Testing: Unit tests for AuthService, integration tests for auth endpoints
         - Acceptance: Users can log in, log out, and access protected routes
     ```
