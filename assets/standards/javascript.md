# JavaScript Standards

## Naming Conventions
Use camelCase for variables and functions. Use PascalCase for classes and constructor functions. Use UPPER_SNAKE_CASE for global constants.

## File Structure
Group by feature or domain rather than file type. Keep files small and modular. Ensure entry points (like index.js) are clear.

## Formatting Rules
Indent with 2 spaces. Use single quotes for strings unless double quotes are needed to avoid escaping. Always use semicolons.

## Best Practices
- Use `const` by default, `let` if reassignment is needed, never `var`.
- Prefer arrow functions for callbacks and preserving `this` context.
- Use template literals instead of string concatenation.
- Use destructuring assignment for objects and arrays.
- Handle asynchronous operations with async/await rather than raw promises where possible.

## Common Pitfalls
- Mutating state directly instead of returning new objects/arrays.
- Forgetting to handle promise rejections or try/catch around await.
- Comparing with `==` instead of strict `===`.
- Creating global variables accidentally by omitting const/let.
- Blocking the main thread with heavy synchronous calculations.

## UI/UX Conventions
- Use non-blocking UI updates (requestAnimationFrame) for animations.
- Provide immediate visual feedback for async actions (loading spinners).
- Debounce or throttle frequent events (scroll, resize, input).
