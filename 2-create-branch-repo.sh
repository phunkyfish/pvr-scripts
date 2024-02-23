#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$SCRIPT_DIR/config/config.ini"

# Need at least 2 args
if [ $# -le 1 ]
then
  echo -e "\nUsage: $0 <repo-name> <branch-name> <patch-path> <commit-message> *<target-path>\n"
  echo -e "Create a branch in a repo, apply the patch with the commit message and push the branch to origin\n"
  echo -e "repo-name: the valid name of a repo."
  echo -e "branch-name: the name of the new branch to be created."
  echo -e "target-path: optional argument specifying the path where the repo should be located. If not specified the current directory will be used.\n"
  echo -e "\nNote: it is assumed the repo's were correctly cloned and configured using \"clone-setup-repo(s).sh\""
  exit 1
fi

REPO_NAME=$1
BRANCH_NAME=$2
TARGET_PATH=$3
# This will only be set when called from multi-run script
MULTI_RUN=$4

if [ -z "$MULTI_RUN" ]
then
	echo -e "Creatig branch \"$BRANCH_NAME\" for repo: $REPO_NAME\n"
fi

. "$SCRIPT_DIR/helper/functions.sh"

#
# Check all the pre-requisites, if any fail a message will be printed and script will exit
#

TARGET_PATH=$(get_target_path)
check_target_path_exists
check_target_repo_path_exists

#
# Call will exit with a message if the repo is not found in the config file
# Note that we always set UPSTREAM_ORG and BASE_BRANCH to themselves in case they are passed in
#

UPSTREAM_ORG=$UPSTREAM_ORG
BASE_BRANCH=$BASE_BRANCH
FOUND=false

. "$SCRIPT_DIR/helper/find-repo-in-repos-list-file.sh"

#
# Time to create the branch in the repo
#

pushd "$TARGET_PATH/$REPO_NAME" > /dev/null 2>&1
git checkout $BASE_BRANCH > /dev/null 2>&1
git pull > /dev/null 2>&1

git show-ref --verify --quiet "refs/heads/$BRANCH_NAME" > /dev/null 2>&1
if [ $? -eq 0 ]; then
	git checkout $BRANCH_NAME > /dev/null 2>&1
	echo "Could not create branch \"$BRANCH_NAME\" as it already exists for repo: $REPO_NAME"
	exit 1
fi

git checkout -b $BRANCH_NAME > /dev/null 2>&1
check_error $? "Could not create branch \"$BRANCH_NAME\""

popd > /dev/null 2>&1

echo "Succesfully created branch \"$BRANCH_NAME\" for repo: $REPO_NAME"
