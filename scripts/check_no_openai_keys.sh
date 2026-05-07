#!/usr/bin/env bash
set -euo pipefail

PATTERN='sk-[A-Za-z0-9._-]{16,}|OPENAI_API_KEY'
TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

git diff --cached --name-only -z | while IFS= read -r -d '' file; do
  # skip if file deleted
  if [ -z "$(git ls-files --error-unmatch -- "$file" 2>/dev/null)" ] && git show :"$file" >/dev/null 2>&1; then
    :
  fi
  if git show :"$file" 2>/dev/null | grep -a -n -E "$PATTERN" >/dev/null 2>&1; then
    echo "Potential OpenAI key found in staged file: $file" >&2
    git show :"$file" 2>/dev/null | grep -a -n -E "$PATTERN" >&2
    echo "$file" >> "$TMPFILE"
  fi
done

if [ -s "$TMPFILE" ]; then
  echo "\nCommit aborted: remove the secret(s) above before committing." >&2
  exit 1
fi

exit 0
