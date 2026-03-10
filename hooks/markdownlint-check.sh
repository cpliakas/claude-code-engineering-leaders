#!/bin/bash

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path')

# Only process .md files
if [[ ! "$file_path" =~ \.md$ ]]; then
  exit 0
fi

# Skip if markdownlint is not installed
if ! command -v markdownlint &> /dev/null; then
  exit 0
fi

# Run markdownlint, excluding line-length (MD013) and first-line-heading (MD041)
# which are expected in agent/skill files with YAML frontmatter
issues=$(markdownlint --disable MD013 MD041 -- "$file_path" 2>&1) || true

if [ -z "$issues" ]; then
  exit 0
fi

# Report issues back to Claude as additional context
json_issues=$(echo "$issues" | jq -Rs .)
cat <<EOF
{"hookSpecificOutput": {"additionalContext": "markdownlint found issues in $file_path:\n$(echo "$issues" | head -20)"}}
EOF
exit 0
