# CSS Standards

## Naming Conventions
Use kebab-case for class names and IDs. Avoid camelCase or snake_case in CSS. Consider BEM (Block Element Modifier) methodology for complex styling.

## File Structure
Separate CSS into logical modules (e.g., reset, typography, layout, components). Use a main entry file that imports the partials.

## Formatting Rules
Indent with 2 spaces. Put each property on its own line. Add a space after the colon. Include a trailing semicolon on the last property.

## Best Practices
- Prefer relative units (rem, em, %) over absolute units (px) for scalability.
- Use CSS variables (--var) for theme colors and consistent spacing.
- Group related selectors rather than repeating blocks.
- Keep specificity as low as possible.
- Design mobile-first using min-width media queries.

## Common Pitfalls
- Overusing `!important` to force overrides.
- Creating deeply nested selectors that are hard to override.
- Using generic class names that cause unexpected conflicts.
- Forgetting vendor prefixes for experimental properties.
- Not resetting default browser margins/padding.

## UI/UX Conventions
- Ensure sufficient color contrast.
- Define explicit `:hover`, `:focus`, and `:active` states for interactables.
- Provide smooth transitions for state changes (e.g., hover effects).
