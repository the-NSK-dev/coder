# Tailwind CSS Standards

## Naming Conventions
Use standard Tailwind utility classes directly. When extracting custom utilities, use kebab-case in the tailwind.config.js theme extension.

## File Structure
Keep the `tailwind.config.js` in the project root. Apply global base styles via an `index.css` file using `@tailwind base; @tailwind components; @tailwind utilities;`.

## Formatting Rules
Sort Tailwind classes logically (e.g., layout, flexbox, spacing, typography, colors, effects). Use a formatter like Prettier with the Tailwind plugin.

## Best Practices
- Extend the default theme in `tailwind.config.js` rather than using arbitrary values (e.g., `text-[#123456]`).
- Use `@apply` sparingly, mostly for highly reusable atomic components like buttons.
- Leverage responsive prefixes (`md:`, `lg:`) for mobile-first design.
- Use state variants (`hover:`, `focus:`, `dark:`) heavily instead of custom CSS.

## Common Pitfalls
- Overusing arbitrary values leading to inconsistent design systems.
- Dynamically constructing class names (e.g., `text-${color}-500`), which breaks Tailwind's PurgeCSS parser.
- Duplicating large blocks of utilities instead of extracting a React/Vue component.
- Forgetting to configure the `content` array in `tailwind.config.js`.

## UI/UX Conventions
- Rely on Tailwind's default spacing and typography scales for a harmonious look.
- Support Dark Mode fully using the `dark:` variant.
- Use Tailwind's transition utilities for smooth interactive states.
