#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$SCRIPT_DIR/config/config.ini"

# Need at least 2 args
if [ $# -le 0 ]
then
	echo -e "\nUsage: $0 <fork-org> <repo-name> *<target-path>\n"
	echo -e "Clone a valid repo, add an \"upstream\" remote and set correct default branch from \"upstream\"\n"
	echo -e "repo-name: the valid name of a repo."
	exit 1
fi

REPO_NAME=$1
# This will only be set when called from multi-run script
MULTI_RUN=$2

if [ -z "$MULTI_RUN" ]
then
	echo -e "Cloning starting for repo: $REPO_NAME\n"
fi

. "$SCRIPT_DIR/helper/functions.sh"

#
# Call will exit with a message if the repo is not found in the config file
# Note that we always set UPSTREAM_ORG and BASE_BRANCH to themselves in case they are passed in
#

UPSTREAM_ORG=$UPSTREAM_ORG
BASE_BRANCH=$BASE_BRANCH
FOUND=false

. "$SCRIPT_DIR/helper/find-repo-in-repos-list-file.sh"

#
# Time to fork the repo!
#

# FORK_CREATE_OUTPUT=`gh repo fork $UPSTREAM_ORG/$REPO_NAME --clone=false 2>&1`
# CREATE_FORK_RET=$?

# if [ $CREATE_FORK_RET -eq 0 ]; then
# 	echo "Succesfully forked repo: $REPO_NAME"
# else
# 	echo "Could not create for of: $REPO_NAME, it may already exist"
# fi
