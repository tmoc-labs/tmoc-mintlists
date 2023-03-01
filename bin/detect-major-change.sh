#!/bin/bash

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
  fi
done

# Check for removed mintlists
for mintlist in $previous_mintlists; do
  if ! echo "$current_mintlists" | grep -q "^$mintlist$"; then
    echo "$mintlist has been removed"
  fi
done
