#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$SCRIPT_DIR/config/config.ini"
SCOPES_LIST=`cat "$SCRIPT_DIR/config/$REPO_PREFIX-scopes.txt" | tr '\n' ' '`

# Need it least 2 args
if [ $# -le 1 ]
then
	echo -e "\nUsage: $0 scope <fork-org> *<target-path>\n"
	echo -e "Clone a number of valid $REPO_PREFIX repos, add \"upstream\" remotes and set correct default branches from \"upstream\" on each\n"
	echo -e "scope: specify a valid scope for \"$REPO_PREFIX\" repos from the list: $SCOPES_LIST"
	echo -e "fork-org: the github user/org where the fork of the upstream $REPO_PREFIX repo resides. Note: it is assumed that the forks exist."
	echo -e "target-path: optional argument specifying the path where the clone should be located. If not specified the current directory will be used.\n"
	exit 1
fi

SCOPE=$1
FORK_ORG=$2
TARGET_PATH=$3

. "$SCRIPT_DIR/helper/functions.sh"

#
# Check all the pre-requisites, if any fail a message will be printed and script will exit
#

check_valid_scope
echo -e "Cloning starting for \"$REPO_PREFIX\" repos with scope: $SCOPE\n"
TARGET_PATH=$(get_target_path)
if [ ! -d "$TARGET_PATH" ]
then
	mkdir -p "$TARGET_PATH" > /dev/null 2>&1
fi
check_any_directories_exist_prior_to_multi_clone_run

#
# Now for every repo starting cloning!
#

while read line; do
	REPO_NAME=`echo $line | awk '{print $1}'`
	UPSTREAM_ORG=`echo $line | awk '{print $2}'`
	BASE_BRANCH=`echo $line | awk '{print $3}'`

	if [ "$SCOPE" = "all" ] || [ "$UPSTREAM_ORG" = "$SCOPE" ]
	then
		"$SCRIPT_DIR/1-clone-setup-repo.sh" "$FORK_ORG" "$REPO_NAME" "$TARGET_PATH" "multi_run"
	fi
done < "$SCRIPT_DIR/config/$REPO_PREFIX-repos.txt"
