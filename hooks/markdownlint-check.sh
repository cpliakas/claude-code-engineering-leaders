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
# which are expected in agent/skill files with YAML frontmatter.
# markdownlint prints findings to stderr; exit code 1 means lint findings,
# any exit code >= 2 is a tool failure (bad config, node error) — surface a
# short notice so a broken setup doesn't silently disable linting.
issues=$(markdownlint --disable MD013 MD041 -- "$file_path" 2>&1)
rc=$?

if [ "$rc" -ge 2 ]; then
  snippet=$(echo "$issues" | head -5)
  jq -n --arg path "$file_path" --arg rc "$rc" --arg out "$snippet" \
    '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: ("markdownlint failed (exit " + $rc + ") on " + $path + "; markdown linting is not running:\n" + $out)}}'
  exit 0
fi

if [ "$rc" -ne 1 ] || [ -z "$issues" ]; then
  exit 0
fi

total=$(echo "$issues" | wc -l | tr -d ' ')
trimmed=$(echo "$issues" | head -20)
if [ "$total" -gt 20 ]; then
  trimmed="$trimmed
(truncated: $((total - 20)) more findings not shown)"
fi

# Report issues back to Claude as additional context
jq -n --arg path "$file_path" --arg issues "$trimmed" \
  '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: ("markdownlint found issues in " + $path + ":\n" + $issues)}}'
exit 0
