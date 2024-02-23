#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$SCRIPT_DIR/config/config.ini"
SCOPES_LIST=`cat "$SCRIPT_DIR/config/binary-addon-scopes.txt" | tr '\n' ' '`

# Need it least 2 args
if [ $# -le 0 ]
then
	echo -e "\nUsage: $0 scope <fork-org> *<target-path>\n"
	echo -e "Clone a number of valid repos, add \"upstream\" remotes and set correct default branches from \"upstream\" on each\n"
	echo -e "scope: specify a valid scope for repos from the list: $SCOPES_LIST"
	exit 1
fi

SCOPE=$1

. "$SCRIPT_DIR/helper/functions.sh"

#
# Check all the pre-requisites, if any fail a message will be printed and script will exit
#

check_valid_scope
echo -e "Forking starting for repos with scope: $SCOPE\n"

#
# Now for every repo starting cloning!
#

while read line; do
	REPO_NAME=`echo $line | awk '{print $1}'`

	if [ "$SCOPE" = "all" ] || [ "$UPSTREAM_ORG" = "$SCOPE" ] || [[ "$SCOPE" = "all-kodi-pvr"  && $REPO_NAME == pvr.* ]]
	then
		"$SCRIPT_DIR/0-fork-repo.sh" "$REPO_NAME" "multi_run"
	fi
done < "$SCRIPT_DIR/config/binary-addon-repos.txt"
