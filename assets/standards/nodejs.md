# Node.js Standards

## Naming Conventions
Use camelCase for functions and variables. Use PascalCase for classes. Use UPPER_SNAKE_CASE for environment variables and constants.

## File Structure
Follow a layered architecture (e.g., controllers, services, routes, models). Keep configuration files in a `config/` directory.

## Formatting Rules
Indent with 2 spaces. Use single quotes. Always use semicolons. Handle errors consistently, usually by passing them to an `errorHandler` middleware in Express.

## Best Practices
- Always use asynchronous APIs (e.g., `fs.promises` instead of `fs.readFileSync`).
- Use environment variables (`process.env`) for secrets and configuration.
- Validate incoming data rigorously before processing.
- Implement proper logging instead of relying solely on `console.log`.
- Handle unhandled promise rejections and uncaught exceptions globally.

## Common Pitfalls
- Blocking the event loop with synchronous, CPU-intensive tasks.
- Ignoring errors in callbacks or catch blocks, leading to silent failures.
- Not setting a timeout on HTTP requests.
- Callback hell (use async/await instead).

## UI/UX Conventions
- Backend language — follow RESTful API design conventions instead. Use standard HTTP status codes (200, 201, 400, 401, 404, 500).
- Return structured JSON responses consistently.
