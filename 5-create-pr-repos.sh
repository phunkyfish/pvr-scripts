#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$SCRIPT_DIR/config/config.ini"
SCOPES_LIST=`cat "$SCRIPT_DIR/config/binary-addon-scopes.txt" | tr '\n' ' '`

# Need it least 4 args
if [ $# -le 3 ]
then
	echo -e "\nUsage: $0 <scope> <branch-name> <pr-title> <pr-body> *<target-path>\n"
	echo -e "Create a PR in the upstream using the given branch in the origin for each repo\n"
	echo -e "scope: specify a valid scope for repos from the list: $SCOPES_LIST"
	echo -e "branch-name: the name of the new branch to be created."
	echo -e "pr-title: the title for the PR."
	echo -e "pr-body: the body for the PR."
	echo -e "target-path: optional argument specifying the path where the clone should be located. If not specified the current directory will be used.\n"
	exit 1
fi

SCOPE=$1
BRANCH_NAME=$2
PR_TITLE=$3
PR_BODY=$4
TARGET_PATH=$5

. "$SCRIPT_DIR/helper/functions.sh"

#
# Check all the pre-requisites, if any fail a message will be printed and script will exit
#

check_valid_scope
echo -e "Create PR in upstream starting for repos with scope: $SCOPE\n"
TARGET_PATH=$(get_target_path)
check_target_path_exists
check_any_directories_missing_prior_to_run

#
# Now for every repo start pushing the branch to origin!
#

while read line; do
	REPO_NAME=`echo $line | awk '{print $1}'`
	UPSTREAM_ORG=`echo $line | awk '{print $2}'`
	BRANCH=`echo $line | awk '{print $3}'`

	if [ "$SCOPE" = "all" ] || [ "$UPSTREAM_ORG" = "$SCOPE" ] || [[ "$SCOPE" = "all-kodi-pvr"  && $REPO_NAME == pvr.* ]]
	then
		"$SCRIPT_DIR/5-create-pr-repo.sh" "$REPO_NAME" "$BRANCH_NAME" "$PR_TITLE" "$PR_BODY" "$TARGET_PATH" "multi_run"
	fi
done < "$SCRIPT_DIR/config/binary-addon-repos.txt"
