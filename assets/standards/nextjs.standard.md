# NEXTJS STANDARD

## USE
- app router with the app directory
- server components by default
- next/image for optimized images
- next/link for client navigation
- metadata exports for SEO

## DO_NOT
- use client on every file
- client-side fetch when server fetch works
- raw img tags for local assets
- blocking data fetches in client components
- hardcoded environment secrets

## REQUIRED_FILES
- package.json
- next.config.js
- app/page.tsx
- app/layout.tsx

## VERIFY_CHECKS
- app_dir_structure
- layout_exists
- imports_resolve
