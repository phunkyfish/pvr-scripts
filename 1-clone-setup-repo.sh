#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$SCRIPT_DIR/config/config.ini"

# Need at least 2 args
if [ $# -le 1 ]
then
	echo -e "\nUsage: $0 <fork-org> <repo-name> *<target-path>\n"
	echo -e "Clone a valid repo, add an \"upstream\" remote and set correct default branch from \"upstream\"\n"
	echo -e "fork-org: the github user/org where the fork of the upstream repo resides. Note: it is assumed that the forks exist."
	echo -e "repo-name: the valid name of a repo."
	echo -e "target-path: optional argument specifying the path where the clone should be located. If not specified the current directory will be used.\n"
	exit 1
fi

FORK_ORG=$1
REPO_NAME=$2
TARGET_PATH=$3
# This will only be set when called from multi-run script
MULTI_RUN=$4

if [ -z "$MULTI_RUN" ]
then
	echo -e "Cloning starting for repo: $REPO_NAME\n"
fi

. "$SCRIPT_DIR/helper/functions.sh"

#
# Check all the pre-requisites, if any fail a message will be printed and script will exit
#

TARGET_PATH=$(get_target_path)
if [ ! -d "$TARGET_PATH" ]
then
	mkdir -p "$TARGET_PATH" > /dev/null 2>&1
fi
check_target_clone_path_not_exists

#
# Call will exit with a message if the repo is not found in the config file
# Note that we always set UPSTREAM_ORG and BASE_BRANCH to themselves in case they are passed in
#

UPSTREAM_ORG=$UPSTREAM_ORG
BASE_BRANCH=$BASE_BRANCH
FOUND=false

. "$SCRIPT_DIR/helper/find-repo-in-repos-list-file.sh"

#
# Time to clone and setup the repo!
#

pushd "$TARGET_PATH" > /dev/null 2>&1
git clone https://github.com/$FORK_ORG/$REPO_NAME > /dev/null 2>&1
check_error $? "Cloning failed"

pushd $REPO_NAME > /dev/null 2>&1
git remote add upstream https://github.com/$UPSTREAM_ORG/$REPO_NAME > /dev/null 2>&1
check_error $? "Could not add remote for upstream"
git fetch upstream > /dev/null 2>&1
check_error $? "Could not fetch upstream"

# We try and checkout the default branch in case it does not exist, if it already exists ignore the error
git checkout -b $BASE_BRANCH > /dev/null 2>&1

git branch -u upstream/$BASE_BRANCH $BASE_BRANCH > /dev/null 2>&1
check_error $? "Could not set default branch to upstream"
git pull > /dev/null 2>&1
check_error $? "Could not pull $BASE_BRANCH"

popd > /dev/null 2>&1
popd > /dev/null 2>&1

echo "Succesfully cloned repo: $REPO_NAME"