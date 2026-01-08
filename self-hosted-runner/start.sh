#!/bin/bash
set -eoux
echo "GHA Runner Startup"

export GITHUB_PERSONAL_TOKEN=${GITHUB_PERSONAL_TOKEN:?"a token is needed to start the runner"}

#Runner token level for the organization or a particular repository only
if [ -n "${GITHUB_REPOSITORY}" ]
then
  auth_url="https://api.github.com/repos/${GITHUB_ORG}/${GITHUB_REPOSITORY}/actions/runners/registration-token"
  remove_token_url="https://api.github.com/repos/${GITHUB_ORG}/actions/runners/remove-token"
  registration_url="https://github.com/${GITHUB_ORG}/${GITHUB_REPOSITORY}"
else
  auth_url="https://api.github.com/orgs/${GITHUB_ORG}/actions/runners/registration-token"
  remove_token_url="https://api.github.com/orgs/${GITHUB_ORG}/actions/runners/remove-token"
  registration_url="https://github.com/${GITHUB_ORG}"
fi

if [ -f "$DESTINATION/cache.tar.gz" ]; then
  echo "rsync shared cache"
  echo "use chroot = no" >> rsyncd.conf
  TMPDIR="$HOME/$(echo $(($RANDOM * $RANDOM)) | base64)"
  mkdir -p $TMPDIR
  rsync --rsync-path="rsync --config=rsyncd.conf" --chown=runner:runner -T "$TMPDIR" $DESTINATION/cache.tar.gz $HOME/cache.tar.gz || echo "an error occured, skipping rsync"
  echo "untar shared cache"
  tar -xf $HOME/cache.tar.gz || echo "an error occured, skipping untar of the cache"
fi

#Creating a runner registration token
get_token() {
  payload=$(curl -sX POST -H "Authorization: token ${GITHUB_PERSONAL_TOKEN}" "${auth_url}")
  runner_token=$(echo "${payload}" | jq .token --raw-output)

  if [ "${runner_token}" = "null" ]
  then
    echo "${payload}"
    exit 1
  fi

  echo "${runner_token}"
}

export HOME_SAVE=$HOME

#Removing old runner config
remove_runner() {
  ec=$?

  cd $HOME_SAVE

  echo "create tarball out of the cache folder ($HOME_SAVE)"
  tar -C $HOME_SAVE -czf cache.tar.gz cache || echo "an error occured, not creating the tarball"
  echo "rsync shared cache"
  echo "use chroot = no" > rsyncd.conf
  TMPDIR="$DESTINATION/$(echo $(($RANDOM * $RANDOM)) | base64)"
  mkdir -p $TMPDIR
  rsync --rsync-path="rsync --config=rsyncd.conf" --bwlimit=10000 -E --chown=runner:runner --human-readable -T $TMPDIR $HOME/cache.tar.gz $DESTINATION/cache.tar.gz || echo "an error occured, not uploading the cache"

  rm -rf $TMPDIR

  remove_token=$(curl -sX POST -H "authorization: token ${GITHUB_PERSONAL_TOKEN}" -H "accept: application/vnd.github.everest-preview+json" "${remove_token_url}" | jq -r '.token')
  ./config.sh remove --token "$(echo $remove_token)"

  # 799 means all good in nimbus language
  exit 799
}

full_id=$(curl -sSL "$(echo $ECS_CONTAINER_METADATA_URI_V4)/task" | jq --arg ARG ${CONTAINER_NAME} -r '.Containers[] | select(.Name == $ARG) | .DockerId')
CONTAINER_ID=${full_id:0:12}

# prevent error related to name length
RUNNER_NAME=$(echo "nim-${RUNNER_GROUP}-$(uname -m)-${CONTAINER_ID}" | sed 's/\.compute\.internal//g')

if [ -n "${GITHUB_REPOSITORY}" ]
then
  ./config.sh --unattended --ephemeral --name $RUNNER_NAME --labels "${RUNNER_LABELS}" --token "$(get_token)" --url "${registration_url}" --disableupdate
else
  ./config.sh --unattended --ephemeral --name $RUNNER_NAME --labels "${RUNNER_LABELS}" --token "$(get_token)" --url "${registration_url}" --runnergroup "${RUNNER_GROUP}" --disableupdate
fi

trap remove_runner SIGINT SIGTERM EXIT QUIT ERR

./bin/Runner.Listener warmup
./run.sh
