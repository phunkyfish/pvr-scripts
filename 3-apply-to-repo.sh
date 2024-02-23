#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$SCRIPT_DIR/config/config.ini"

# Need at least 5 args
if [ $# -le 4 ]
then
	echo -e "\nUsage: $0 <repo-name> <branch-name> <patch-path> <commit-message> *<target-path>\n"
	echo -e "Apply a patch or script with the given commit message to the root of the repo for the given branch\n"
	echo -e "repo-name: the valid name of arepo."
	echo -e "branch-name: the name of the new branch to be created."
	echo -e "file-type: patch|script for a patch file or script to be executed as a child process"
	echo -e "file-path: the path to the file to be applied to the root of the repo. Will be applied with \"patch -p1 < file-path\" if it's patch file, otherwise as a child process."
	echo -e "commit-message: the commit message to use for the patch."
	echo -e "target-path: optional argument specifying the path where the repo should be located. If not specified the current directory will be used.\n"
	echo -e "\nNote: it is assumed the repo's were correctly cloned and configured using \"clone-setup-repo(s).sh\""
	exit 1
fi

REPO_NAME=$1
BRANCH_NAME=$2
FILE_TYPE=$3
FILE_PATH=$4
COMMIT_MESSAGE=$5
TARGET_PATH=$6
# This will only be set when called from multi-run script
MULTI_RUN=$7

if [ -z "$MULTI_RUN" ]
then
	echo -e "Applying $FILE_TYPE \"$FILE_PATH\" to branch \"$BRANCH_NAME\" for repo: $REPO_NAME\n"
fi

. "$SCRIPT_DIR/helper/functions.sh"

#
# Check all the pre-requisites, if any fail a message will be printed and script will exit
#

TARGET_PATH=$(get_target_path)
check_target_path_exists
check_target_repo_path_exists
check_valid_file_type
check_valid_file_path

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

ABS_FILE_PATH="$( cd "$( dirname "$FILE_PATH")"; pwd)/$(basename "$FILE_PATH")"

pushd "$TARGET_PATH/$REPO_NAME" > /dev/null 2>&1
git checkout $BRANCH_NAME > /dev/null 2>&1
check_error $? "Failed to apply patch as branch \"$BRANCH_NAME\" does not exist"

if [ "$FILE_TYPE" = "patch" ]
then
patch -p1 < "$ABS_FILE_PATH" > /dev/null 2>&1
check_error $? "$FILE_TYPE failed"
else
"$ABS_FILE_PATH" > /dev/null 2>&1
check_error $? "$FILE_TYPE failed"
fi
git add -u
git commit -m "$COMMIT_MESSAGE" > /dev/null 2>&1
check_error $? "Nothing to commit, likely an issue with the $FILE_TYPE file"

popd > /dev/null 2>&1

echo "Succesfully applied $FILE_TYPE to branch \"$BRANCH_NAME\" for repo: $REPO_NAME"
