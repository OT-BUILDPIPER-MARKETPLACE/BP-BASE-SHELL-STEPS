#!/bin/bash

execute_command() {
  local command="$1"

  # Define patterns to mask (e.g., tokens, passwords, secrets)
  # You can extend this to handle more cases
  local sensitive_patterns=("--token [^ ]*" "--password [^ ]*" "--secret [^ ]*" "password=[^ ]*" "token=[^ ]*")

  # Mask sensitive data in the logged command
  local masked_command="$command"
  for pattern in "${sensitive_patterns[@]}"; do
    masked_command=$(echo "$masked_command" | sed -E "s/$pattern/--[REDACTED]/g")
  done

  logInfoMessage "Executing: $masked_command"

  # Execute the actual command and capture the output
  output=$($command 2>&1)
  local status=$?

  # Filter out SLF4J messages from the output
  echo "$output" | grep -v "SLF4J"

  # Check if the command succeeded or failed
  if [ $status -ne 0 ]; then
    logErrorMessage "Command failed: $masked_command"
    exit $status
  else
    logInfoMessage "Command succeeded: $masked_command"
  fi
}


# Function to execute a command and capture its output
execute_command_with_output() {
  local command="$1"
  logInfoMessage "Executing: $command"
  output=$(eval "$command" 2>&1 | grep -v "SLF4J")
  local status=$?
  if [ $status -ne 0 ]; then
    logErrorMessage "Command failed: $command"
    exit $status
  else
    logInfoMessage "Command succeeded: $command"
    echo "$output"
  fi
}