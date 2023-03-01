#!/bin/bash

major_change=false
minor_change=false
patch_change=false

# Define the directories to check
previous_dir="HEAD^"
current_dir="HEAD"
mintlists_dir="src/mintlists/"

# Get the list of mintlist files in the previous commit
previous_mintlists=$(git ls-tree --name-only $previous_dir $mintlists_dir)

# Get the list of mintlist files in the current commit
current_mintlists=$(git ls-tree --name-only $current_dir $mintlists_dir)

# Check for added mintlists
for mintlist in $current_mintlists; do
  if ! echo "$previous_mintlists" | grep -q "^$mintlist$"; then
    echo "$mintlist has been added"
    major_change=true
  fi
done

# Check for removed mintlists
for mintlist in $previous_mintlists; do
  if ! echo "$current_mintlists" | grep -q "^$mintlist$"; then
    echo "$mintlist has been removed"
    major_change=true
  fi
done

# Files that have been changed
changed_files=$(git diff --name-only --diff-filter=d HEAD~1 HEAD | grep "^src/mintlists/.*\.mintlist\.json$")

# Loop through each mintlist file
for file in $changed_files; do
  # Check if the file exists in both commits
  should_test=$(git diff --name-only HEAD~1 HEAD | grep -q "$file")
  if [ -n "$should_test" ]; then
    # Compare the mints arrays in both versions of the file
    removed_mints=$(comm -13 \
      <(jq -r '.mints | sort[]' <(git show HEAD:"$file")) \
      <(jq -r '.mints | sort[]' <(git show HEAD~1:"$file"))
    )

    added_mints=$(comm -13 \
      <(jq -r '.mints | sort[]' <(git show HEAD~1:"$file")) \
      <(jq -r '.mints | sort[]' <(git show HEAD:"$file"))
    )

    # Output any removed mints
    if [ -n "$removed_mints" ]; then
      echo "Mints removed from $file:"
      echo "$removed_mints"
      echo
      minor_change=true
    fi

    if [ -n "$added_mints" ]; then
      echo "Mints added to $file:"
      echo "$added_mints"
      echo
      patch_change=true
    fi
  fi
done

echo "major_change=$major_change"
echo "minor_change=$minor_change"
echo "patch_change=$patch_change"
