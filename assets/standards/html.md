# HTML Standards

## Naming Conventions
Use lowercase for all tags and attributes. Use hyphens for custom data attributes (data-*). IDs and classes should be lowercase with hyphens (kebab-case).

## File Structure
Keep HTML files close to their related CSS/JS if component-based, or in a structured `public/` or `src/` folder for traditional sites.

## Formatting Rules
Indent with 2 spaces. Omit optional closing tags only when strictly minifying, otherwise include them for readability. Use double quotes for attributes.

## Best Practices
- Always use semantic HTML5 tags (<header>, <main>, <article>, <nav>).
- Include `alt` attributes on all <img> tags.
- Use <button> for actions, <a> for navigation.
- Ensure proper ARIA roles for custom interactive elements.
- Keep the DOM tree as shallow as possible.

## Common Pitfalls
- Forgetting the <!DOCTYPE html> declaration.
- Using inline styles or scripts instead of external files.
- Using <div> and <span> everywhere instead of semantic tags.
- Missing <label> for form inputs.
- Incorrect nesting of block vs inline elements.

## UI/UX Conventions
- Use visually distinct active/focus states.
- Ensure logical tab order matching visual layout.
- Support responsive viewport scaling with `<meta name="viewport" ...>`
