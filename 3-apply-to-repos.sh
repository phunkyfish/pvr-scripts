#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$SCRIPT_DIR/config/config.ini"
SCOPES_LIST=`cat "$SCRIPT_DIR/config/binary-addon-scopes.txt" | tr '\n' ' '`

# Need at least 5 args
if [ $# -le 4 ]
then
	echo -e "\nUsage: $0 scope <fork-org> *<target-path>\n"
	echo -e "Apply a patch or script in each repo\n"
	echo -e "scope: specify a valid scope for repos from the list: $SCOPES_LIST"
	echo -e "branch-name: the name of the new branch to be created."
	echo -e "file-type: patch|script for a patch file or script to be executed as a child process"
	echo -e "file-path: the path to the file to be applied to the root of the repo. Will be applied with \"patch -p1 < file-path\" if it's patch file, otherwise as a child process."
	echo -e "commit-message: the commit message to use for the patch."
	echo -e "target-path: optional argument specifying the path where the clone should be located. If not specified the current directory will be used.\n"
	exit 1
fi

SCOPE=$1
BRANCH_NAME=$2
FILE_TYPE=$3
FILE_PATH=$4
COMMIT_MESSAGE=$5
TARGET_PATH=$6

. "$SCRIPT_DIR/helper/functions.sh"

#
# Check all the pre-requisites, if any fail a message will be printed and script will exit
#

check_valid_scope
echo -e "Apply $FILE_TYPE starting for repos with scope: $SCOPE\n"
TARGET_PATH=$(get_target_path)
check_target_path_exists
check_valid_file_type
check_valid_file_path
check_any_directories_missing_prior_to_run

#
# Now for every repo start patching!
#

while read line; do
	REPO_NAME=`echo $line | awk '{print $1}'`
	UPSTREAM_ORG=`echo $line | awk '{print $2}'`
	BRANCH=`echo $line | awk '{print $3}'`

	if [ "$SCOPE" = "all" ] || [ "$UPSTREAM_ORG" = "$SCOPE" ] || [[ "$SCOPE" = "all-kodi-pvr"  && $REPO_NAME == pvr.* ]]
	then
		"$SCRIPT_DIR/3-apply-to-repo.sh" "$REPO_NAME" "$BRANCH_NAME" "$FILE_TYPE" "$FILE_PATH" "$COMMIT_MESSAGE" "$TARGET_PATH" "multi_run"
	fi
done < "$SCRIPT_DIR/config/binary-addon-repos.txt"
