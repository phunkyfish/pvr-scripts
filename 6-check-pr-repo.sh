#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$SCRIPT_DIR/config/config.ini"

# Need at least 2 args
if [ $# -le 1 ]
then
  echo -e "\nUsage: $0 <repo-name> <branch-name> *<target-path>\n"
  echo -e "Check the PR in the upstream using the given branch in the origin repo has passed all it's checks\n"
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
	echo -e "Verify PR checks using \"$BRANCH_NAME\" for repo: $REPO_NAME\n"
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
# Time to check the PR
#

pushd "$TARGET_PATH/$REPO_NAME" > /dev/null 2>&1
git checkout $BRANCH_NAME > /dev/null 2>&1
ORIGIN_USER=`git remote -v | grep origin | grep fetch | awk -F "/" '{print $4}'`

PR_CREATE_OUTPUT=`gh pr create --repo $UPSTREAM_ORG/$REPO_NAME --base $BASE_BRANCH --head $ORIGIN_USER:$BRANCH_NAME --title="test" --body="test" 2>&1`
CREATE_PR_RET=$?
PR_URL=`echo $PR_CREATE_OUTPUT | awk '{print $NF}' | grep https`

popd > /dev/null 2>&1

if [ -z "$PR_URL" ]
then
	echo -e "ERROR: PR does not exist for branch \"$BRANCH_NAME\" in repo: $REPO_NAME"
else
	NUM_CHECKS=`gh pr checks $PR_URL 2>&1 | grep https | wc -l`
	TOTAL_PASSES=`gh pr checks $PR_URL 2>&1 | grep https | grep pass | wc -l`
	TOTAL_FAILS=`gh pr checks $PR_URL 2>&1 | grep https | grep fail | wc -l`

	if [ $NUM_CHECKS -eq $TOTAL_PASSES ]; then
		echo "Successully passed all checks, PR ready for merge: $PR_URL, for repo: $REPO_NAME"
	else
		if [ $TOTAL_FAILS -eq 0 ]; then
			echo "WARNING: Wait for checks to finish ($TOTAL_PASSES of $NUM_CHECKS passing) for: $PR_URL, for repo: $REPO_NAME"
		else
			echo "ERROR: Failure for checks ($TOTAL_FAILS of $NUM_CHECKS failed) for: $PR_URL, for repo: $REPO_NAME"
		fi
	fi
fi
