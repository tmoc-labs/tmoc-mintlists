#!/bin/bash

# Regular expression for valid mintlist.json file names
regex='^[a-zA-Z0-9-]\+\(?=[a-zA-Z]\).*\.mintlist\.json$'

# Get the list of mintlist.json files that were added or removed
mintlist_files=$(git diff --name-only HEAD^ HEAD -- src/mintlists | grep -E "$regex")

# Get the list of mintlist.json files that exist in the previous commit
prev_mintlist_files=$(git ls-tree --name-only -r HEAD^ | grep -E "$regex")

# Initialize variables for version change detection
major_change=false
minor_change=false
patch_change=false

# Check if any new mintlist files were added
if grep -q -v -F -x -f <(echo "$prev_mintlist_files") <(echo "$mintlist_files"); then
  major_change=true
fi

# Check if any existing mintlist files were removed
if grep -q -v -F -x -f <(echo "$mintlist_files") <(echo "$prev_mintlist_files"); then
  major_change=true
fi

# Loop through each mintlist.json file
for file in $mintlist_files
do
  # Get the previous version of the mintlist.json file
  prev_contents=$(git show HEAD^:"$file")

  # Extract the mints from the current and previous JSON using jq
  mints=$(jq -r '.mints[]' "$file")
  prev_mints=$(jq -r '.mints[]' <(echo "$prev_contents"))

  # Check if any mints were removed or added
  while read -r mint; do
    if ! echo "$prev_mints" | grep -q "$mint"; then
      minor_change=true
    fi
  done <<< "$mints"

  while read -r prev_mint; do
    if ! echo "$mints" | grep -q "$prev_mint"; then
      minor_change=true
    fi
  done <<< "$prev_mints"
done

# Determine the appropriate version change
if $major_change; then
  npm version major -s
elif $minor_change; then
  npm version minor -s
elif $patch_change; then
  npm version patch -s
else
  echo "::set-output name=no_version_change::true"
fi
