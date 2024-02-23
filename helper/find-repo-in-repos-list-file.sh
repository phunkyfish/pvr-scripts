#!/bin/bash

UPSTREAM_ORG=
BASE_BRANCH=
FOUND=false

while read line; do
	repo=`echo $line | awk '{print $1}'`
	UPSTREAM_ORG=`echo $line | awk '{print $2}'`
	BASE_BRANCH=`echo $line | awk '{print $3}'`

	if [ "$repo" = "$REPO_NAME" ]; then
		FOUND=true
		if [ "$DEBUG" = "true" ]
		then
			echo "DEBUG: Found repo: $REPO_NAME"
		fi

		if [ "$BASE_BRANCH" = "default" ]; then
			BASE_BRANCH=$DEFAULT_BRANCH
		fi

		if [ "$DEBUG" = "true" ]
		then
			echo "DEBUG: Upstream uses default branch: $BASE_BRANCH and user/org: $UPSTREAM_ORG"
		fi

		break
	fi
done < "$SCRIPT_DIR/config/binary-addon-repos.txt"

if [ "$FOUND" != "true" ]
then
	echo -e "\nERROR: Config details for repo $REPO_NAME could not be found\n"
	exit 1
fi
