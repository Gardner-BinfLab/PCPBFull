#!/bin/bash

# To get a list of runs for a specific experiment

# Get the experiment_ID as a parameter
experiment_ID="$1"

# Check if the directory exists
if [[ ! -d "data/runs/${experiment_ID}/" ]]; then
  echo "The directory for experiment ID ${experiment_ID} does not exist."
  echo "Creating directory data/runs/${experiment_ID}/"
  mkdir -p "data/runs/${experiment_ID}"
  exit 1
fi

# Read the directories (runs) into an array
options=()
for dir in "data/runs/${experiment_ID}/"*/; do
  options+=("$(basename -- "$dir")")
done

# Check if there are any runs
if [[ ${#options[@]} -eq 0 ]]; then
  echo "No runs found for experiment ID ${experiment_ID}." >&2
  exit 2
fi

# Prompt the user to select a run
echo "Please select a run:" >&2
select run in "${options[@]}"; do
  if [[ -n $run ]]; then
    echo "You selected run: $run" >&2
    break
  else
    echo "Invalid option. Please try again." >&2
  fi
done

# Return the selected run to the calling script
echo "$run"

