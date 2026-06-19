# Java Standards

## Naming Conventions
Use PascalCase for Classes and Interfaces. Use camelCase for methods and variables. Use UPPER_SNAKE_CASE for `static final` constants. Packages should be all lowercase.

## File Structure
One public class per file. File name must exactly match the public class name. Organize files into packages matching directory structure (e.g., `src/main/java/com/example/project/`).

## Formatting Rules
Indent with 4 spaces. Place the opening brace on the same line as the declaration. Place the closing brace on a new line.

## Best Practices
- Always use access modifiers (private, protected, public) intentionally.
- Prefer Interfaces over concrete implementations for typing (e.g., `List<String>` instead of `ArrayList<String>`).
- Use `@Override` annotations whenever implementing or overriding methods.
- Handle Exceptions specifically; avoid catching generic `Exception` unless at the top level.
- Use dependency injection to decouple components.

## Common Pitfalls
- `NullPointerException`: forgetting to check for nulls or not using `Optional`.
- Comparing Strings with `==` instead of `.equals()`.
- Resource leaks: not using try-with-resources for I/O and database connections.
- Modifying collections while iterating over them (without an Iterator).

## UI/UX Conventions
- Backend language — follow RESTful API design conventions instead.
- If writing JavaFX/Swing, ensure long-running tasks are kept off the Event Dispatch Thread.
