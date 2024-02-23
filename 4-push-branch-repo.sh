#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$SCRIPT_DIR/config/config.ini"

# Need at least 3 args
if [ $# -le 2 ]
then
	echo -e "\nUsage: $0 <repo-name> <branch-name> <patch-path> <commit-message> *<target-path>\n"
	echo -e "Push the specified branch to origin for the specified repo\n"
	echo -e "repo-name: the valid name of a repo."
	echo -e "branch-name: the name of the new branch to be created."
	echo -e "force-push: true|false if the branch shoudl be force pushed"
	echo -e "target-path: optional argument specifying the path where the repo should be located. If not specified the current directory will be used.\n"
	echo -e "\nNote: it is assumed the repo's were correctly cloned and configured using \"clone-setup-repo(s).sh\""
	exit 1
fi

REPO_NAME=$1
BRANCH_NAME=$2
FORCE_PUSH=$3
TARGET_PATH=$4
# This will only be set when called from multi-run script
MULTI_RUN=$5

if [ -z "$MULTI_RUN" ]
then
	echo -e "Pushing branch \"$BRANCH_NAME\" for repo: $REPO_NAME\n"
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
# Time to push the branch to the origin repo
#

pushd "$TARGET_PATH/$REPO_NAME" > /dev/null 2>&1

OPTIONS=
if [ "$FORCE_PUSH" = "true" ]
then
	OPTIONS="-ff"
fi
git push origin $OPTIONS $BRANCH_NAME > /dev/null 2>&1
check_error $? "Could not push branch \"$BRANCH_NAME\" to origin due to an error"

popd > /dev/null 2>&1

if [ "$FORCE_PUSH" = "true" ]
then
	echo "Succesfully FORCE pushed branch \"$BRANCH_NAME\" to origin for repo: $REPO_NAME"
else
	echo "Succesfully pushed branch \"$BRANCH_NAME\" to origin for repo: $REPO_NAME"
fi
