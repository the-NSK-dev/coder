# React Standards

## Naming Conventions
Use PascalCase for component files and function names (e.g., `UserProfile.jsx`). Use camelCase for props, local variables, and standard helper functions.

## File Structure
Group components by feature folder. Each feature folder should have an `index.js`, the component file, and its specific tests/styles.

## Formatting Rules
Indent with 2 spaces. Use JSX syntax (with .jsx or .tsx extension). Close all tags explicitly. Wrap multi-line JSX in parentheses.

## Best Practices
- Use functional components and React Hooks instead of class components.
- Keep components small and focused on a single responsibility.
- Use the `useMemo` and `useCallback` hooks for expensive calculations, but don't over-optimize.
- Extract complex state logic into custom hooks.
- Validate props with PropTypes or use TypeScript.

## Common Pitfalls
- Mutating state directly instead of using the setState function.
- Omitting the dependency array in `useEffect`, causing infinite loops.
- Stale closures in `useEffect` or `useCallback` due to missing dependencies.
- Using array indexes as `key` props when the list can change order.
- Overusing context for state that only affects a small part of the tree.

## UI/UX Conventions
- Implement error boundaries to prevent whole-app crashes.
- Provide fallback UI (Suspense/loading states) during async operations.
- Ensure accessible markup (aria-labels, proper roles) in JSX.
