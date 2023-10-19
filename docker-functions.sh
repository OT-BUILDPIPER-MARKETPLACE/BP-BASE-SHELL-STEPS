#!/bin/bash

# Function to extract the base image from a filtered Dockerfile string
# This string contains entries of all the lines starting with FROM
getBaseImageFromFilteredDockerfile() {
  local allFromEntries="$1"
  local base_img

  while IFS= read -r line; do
    base_img=$(echo "$line" | grep '^FROM ' | awk '{print $2}')
  done <<< "$allFromEntries"

  echo "${base_img}"
}
