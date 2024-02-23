#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$SCRIPT_DIR/config/config.ini"
SCOPES_LIST=`cat "$SCRIPT_DIR/config/binary-addon-scopes.txt" | tr '\n' ' '`

# Need it least 3 args
if [ $# -le 2 ]
then
	echo -e "\nUsage: $0 <scope> <branch-name> <force-push> *<target-path>\n"
	echo -e "Push the specified branch to origin for each repo\n"
	echo -e "scope: specify a valid scope for repos from the list: $SCOPES_LIST"
	echo -e "branch-name: the name of the new branch to be created."
	echo -e "force-push: true|false if the branch shoudl be force pushed"
	echo -e "target-path: optional argument specifying the path where the clone should be located. If not specified the current directory will be used.\n"
	exit 1
fi

SCOPE=$1
BRANCH_NAME=$2
FORCE_PUSH=$3
TARGET_PATH=$4

. "$SCRIPT_DIR/helper/functions.sh"

#
# Check all the pre-requisites, if any fail a message will be printed and script will exit
#

check_valid_scope
echo -e "Push branch to origin starting for repos with scope: $SCOPE\n"
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
		"$SCRIPT_DIR/4-push-branch-repo.sh" "$REPO_NAME" "$BRANCH_NAME" "$FORCE_PUSH" "$TARGET_PATH" "multi_run"
	fi
done < "$SCRIPT_DIR/config/binary-addon-repos.txt"
