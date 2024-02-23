#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$SCRIPT_DIR/config/config.ini"

# Need at least 4 args
if [ $# -le 3 ]
then
	echo -e "\nUsage: $0 <repo-name> <branch-name> <pr-title> <pr-body> *<target-path>\n"
	echo -e "Create a PR in the upstream using the given branch in the origin repo\n"
	echo -e "repo-name: the valid name of a repo."
	echo -e "branch-name: the name of the new branch to be created."
	echo -e "pr-title: the title for the PR."
	echo -e "pr-body: the body for the PR."
	echo -e "target-path: optional argument specifying the path where the repo should be located. If not specified the current directory will be used.\n"
	echo -e "\nNote: it is assumed the repo's were correctly cloned and configured using \"clone-setup-repo(s).sh\""
	exit 1
fi

REPO_NAME=$1
BRANCH_NAME=$2
PR_TITLE=$3
PR_BODY=$4
TARGET_PATH=$5
# This will only be set when called from multi-run script
MULTI_RUN=$6

if [ -z "$MULTI_RUN" ]
then
	echo -e "Creating PR using \"$BRANCH_NAME\" for repo: $REPO_NAME\n"
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
# Time to create the PR
#

pushd "$TARGET_PATH/$REPO_NAME" > /dev/null 2>&1
ORIGIN_USER=`git remote -v | grep origin | grep fetch | awk -F "/" '{print $4}'`
#gh pr create --repo $UPSTREAM_ORG/$REPO_NAME --base $BASE_BRANCH --head $ORIGIN_USER:$BRANCH_NAME --title="$PR_TITLE" --body="$PR_BODY"
PR_CREATE_OUTPUT=`gh pr create --repo $UPSTREAM_ORG/$REPO_NAME --base $BASE_BRANCH --head $ORIGIN_USER:$BRANCH_NAME --title="$PR_TITLE" --body="$PR_BODY" 2>&1`
CREATE_PR_RET=$?
PR_URL=`echo $PR_CREATE_OUTPUT | awk '{print $NF}'`

popd > /dev/null 2>&1

if [ $CREATE_PR_RET -eq 0 ]; then
	echo "Succesfully created PR: $PR_URL, for repo: $REPO_NAME"
else
	PR_URL=`echo $PR_URL | grep $UPSTREAM_ORG/$REPO_NAME`
	check_error $? "Could not create PR for branch \"$BRANCH_NAME\" on upstream due to an error"

	echo "WARNING: Could not create PR for branch \"$BRANCH_NAME\" as it already exists here: $PR_URL, for repo: $REPO_NAME"
fi
