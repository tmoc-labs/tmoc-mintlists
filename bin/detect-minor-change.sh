#!/bin/bash

# Loop through each mintlist file
for file in $(git diff --name-only --diff-filter=d HEAD~1 HEAD | grep "^src/mintlists/.*\.mintlist\.json$"); do
  # Check if the file exists in both commits
  if git diff --name-only HEAD~1 HEAD | grep -q "$file"; then
    # Compare the mints arrays in both versions of the file
    removed_mints=$(jq -r --argjson old "$(git show HEAD~1:"$file")" --argjson new "$(git show HEAD:"$file")" '
      $old.mints as $old
      | $new.mints as $new
      | reduce $old[] as $o ([]; if ($o | IN($new[])) then . else . + [$o] end)
    ')

    # Output any removed mints
    if [ -n "$removed_mints" ]; then
      echo "Mints removed from $file:"
      echo "$removed_mints"
      echo
    fi
  fi
done
