# NODEJS STANDARD

## USE
- async and await for asynchronous operations
- environment variables for configuration
- structured error handling with try and catch
- module exports with clear interfaces
- a defined start script in package.json

## DO_NOT
- synchronous file system calls in request handlers
- hardcoded credentials
- unhandled promise rejections
- blocking the event loop with heavy computation
- callback nesting beyond two levels

## REQUIRED_FILES
- package.json
- index.js

## VERIFY_CHECKS
- syntax_js
- has_start_script
- no_hardcoded_secrets
