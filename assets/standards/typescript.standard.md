# TYPESCRIPT STANDARD

## USE
- explicit return types on exported functions
- interface or type aliases for object shapes
- strict null checks
- readonly for immutable fields
- enums or union types for fixed value sets

## DO_NOT
- any type annotations
- non-null assertions without justification
- var declarations
- implicit any on function parameters
- ts-ignore comments

## REQUIRED_FILES
- tsconfig.json

## VERIFY_CHECKS
- syntax_ts
- no_var_usage
- no_any_type
