# Next.js Standards

## Naming Conventions
Use lowercase for all route files and folders in the `app/` or `pages/` directory. Use PascalCase for React component definitions inside those files.

## File Structure
Follow the App Router structure (`app/page.tsx`, `app/layout.tsx`). Keep shared UI components, hooks, and utilities in separate `components/`, `hooks/`, and `lib/` directories outside the routing folders.

## Formatting Rules
Follow React formatting rules. Ensure all server components and client components are explicitly marked with `"use client"` when necessary.

## Best Practices
- Default to Server Components for better performance and SEO.
- Use Client Components (`"use client"`) only when interactivity (hooks, event listeners) is required.
- Use `next/image` and `next/link` instead of raw `<img>` and `<a>` tags.
- Leverage Server Actions for data mutations instead of building separate API routes when possible.
- Use the Metadata API in `layout.tsx` or `page.tsx` for SEO.

## Common Pitfalls
- Using `"use client"` at the top of every file unnecessarily, losing SSR benefits.
- Passing non-serializable data (functions, Dates) from Server to Client Components.
- Forgetting that Server Components cannot access browser APIs like `window` or `localStorage`.
- Fetching data on the client side when it could have been fetched on the server.

## UI/UX Conventions
- Utilize `loading.tsx` and `error.tsx` for built-in stream loading states and error boundaries.
- Preload critical fonts and optimize LCP images.
