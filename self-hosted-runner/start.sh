#!/bin/bash
set -eou pipefail
echo "GHA Runner Startup"

# Require GitHub token
export GITHUB_PERSONAL_TOKEN=${GITHUB_PERSONAL_TOKEN:?"A token is needed to start the runner"}

# Determine URLs based on repo vs org runner
if [ -n "${GITHUB_REPOSITORY:-}" ]; then
  auth_url="https://api.github.com/repos/${GITHUB_ORG}/${GITHUB_REPOSITORY}/actions/runners/registration-token"
  registration_url="https://github.com/${GITHUB_ORG}/${GITHUB_REPOSITORY}"
else
  auth_url="https://api.github.com/orgs/${GITHUB_ORG}/actions/runners/registration-token"
  registration_url="https://github.com/${GITHUB_ORG}"
fi

# Function to get ephemeral runner token
get_token() {
  payload=$(curl -sX POST -H "Authorization: token ${GITHUB_PERSONAL_TOKEN}" "${auth_url}")
  runner_token=$(echo "${payload}" | jq -r .token)
  if [ "${runner_token}" = "null" ]; then
    echo "Failed to get runner token:" >&2
    echo "${payload}" >&2
    exit 1
  fi
  echo "${runner_token}"
}

# Generate unique runner name per container
CONTAINER_ID=$(curl -sSL "${ECS_CONTAINER_METADATA_URI_V4}/task" \
  | jq -r --arg NAME "${CONTAINER_NAME}" '.Containers[] | select(.Name==$NAME) | .DockerId')
CONTAINER_ID=${CONTAINER_ID:0:12}
if [ -z "$CONTAINER_ID" ]; then
    CONTAINER_ID="$(date +%s)-$RANDOM"
fi

RUNNER_NAME="gha-${RUNNER_GROUP}-$(uname -m)-${CONTAINER_ID}"

# Register the runner
if [ -n "${GITHUB_REPOSITORY:-}" ]; then
  ./config.sh --unattended --ephemeral \
    --name "$RUNNER_NAME" \
    --labels "${RUNNER_LABELS}" \
    --token "$(get_token)" \
    --url "${registration_url}" \
    --disableupdate
else
  ./config.sh --unattended --ephemeral \
    --name "$RUNNER_NAME" \
    --labels "${RUNNER_LABELS}" \
    --token "$(get_token)" \
    --url "${registration_url}" \
    --runnergroup "${RUNNER_GROUP}" \
    --disableupdate
fi

# Trap to safely stop runner and kill any child processes
cleanup() {
  echo "Stopping runner..."
  pkill -P $$ || true  # Kill any child processes
}
trap cleanup SIGINT SIGTERM EXIT

# Run the listener for a single job then exit
./bin/Runner.Listener run --ephemeral


