#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$SCRIPT_DIR/config/config.ini"

# Need at least 3 args
if [ $# -le 2 ]
then
   echo -e "\nUsage: $0 <repo-name> <version-type> <changelog-message> *<target-path>\n"
   echo -e "Add a changelog and version commit to the upstream repo and tag a release.\n"
   echo -e "repo-name: the valid name of a repo."
   echo -e "version-type: minor|micro minor for new features, micro for fixes and language updates"
   echo -e "changelog-message: the changelog message to use in the commit."
   echo -e "target-path: optional argument specifying the path where the repo should be located. If not specified the current directory will be used.\n"
   echo -e "\nNote: it is assumed the repo's were correctly cloned and configured using \"clone-setup-repo(s).sh\""
  exit 1
fi

REPO_NAME=$1
VERSION_TYPE=$2
CHANGELOG_MESSAGE=$3
TARGET_PATH=$4
# This will only be set when called from multi-run script
MULTI_RUN=$5

if [ -z "$MULTI_RUN" ]
then
	echo -e "Creating release with changelog or repo: $REPO_NAME\n"
fi

. "$SCRIPT_DIR/helper/functions.sh"

#
# Check all the pre-requisites, if any fail a message will be printed and script will exit
#

TARGET_PATH=$(get_target_path)
check_target_path_exists
check_target_repo_path_exists

if [ "$VERSION_TYPE" != "minor" ] && [ "$VERSION_TYPE" != "micro" ]
then
	echo -e "ERROR: version-type must be set to either \"minor\" or \"micro\""
	exit 1
fi

#
# Call will exit with a message if the repo is not found in the config file
# Note that we always set UPSTREAM_ORG and BASE_BRANCH to themselves in case they are passed in
#

UPSTREAM_ORG=$UPSTREAM_ORG
BASE_BRANCH=$BASE_BRANCH
FOUND=false

. "$SCRIPT_DIR/helper/find-repo-in-repos-list-file.sh"

#
# Time to add change and release the repo
#

pushd "$TARGET_PATH/$REPO_NAME" > /dev/null 2>&1
# e.g. gh --repo kodi-pvr/pvr.iptvsimple --ref Matrix workflow run changelog-and-release.yml -f version_type=minor -f changelog_text="-\ change1\\\n-\ change2"
gh --repo $UPSTREAM_ORG/$REPO_NAME --ref $BASE_BRANCH workflow run changelog-and-release.yml -f version_type=$VERSION_TYPE -f changelog_text="$CHANGELOG_MESSAGE" > /dev/null 2>&1
check_error $? "Failed to start changelog and release workflow"

echo "Successfully initiated changelog and release workflow for repo: $REPO_NAME"

popd > /dev/null 2>&1
