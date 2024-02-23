#!/bin/bash

check_error()
{
	RET=$1
	ERROR_MSG=$2
	if [ $RET -ne 0 ]; then
   		echo "ERROR: $ERROR_MSG for repo: $REPO_NAME"
		exit 1
	fi
}

get_target_path()
{
	if [ -z "$TARGET_PATH" ]
	then
		echo "."
	else
		echo "$TARGET_PATH"
	fi
}

check_target_clone_path_not_exists()
{
	if [ -d "$TARGET_PATH/$REPO_NAME" ]
	then
		echo -e "ERROR: Cannot clone \"$REPO_NAME\" repo, path already exists: $TARGET_PATH/$REPO_NAME"
		exit 1
	fi
}

check_target_repo_path_exists()
{
	if [ ! -d "$TARGET_PATH/$REPO_NAME" ]
	then
		echo -e "ERROR: Cannot process \"$REPO_NAME\" repo, path does not exist: $TARGET_PATH/$REPO_NAME"
		exit 1
	fi
}

check_target_path_exists()
{
	if [ ! -d "$TARGET_PATH" ]
	then
		echo -e "ERROR: Target path does not exist: $TARGET_PATH"
		exit 1
	fi
}

check_valid_scope()
{
	if ! grep "$SCOPE" "$SCRIPT_DIR/config/binary-addon-scopes.txt" > /dev/null 2>&1;
	then
		echo -e "ERROR: scope must be set to one of: $SCOPES_LIST"
		exit 1
	fi
}

check_valid_file_type()
{
	if [ "$FILE_TYPE" != "patch" ] && [ "$FILE_TYPE" != "script" ]
	then
		echo -e "ERROR: file type must be set to either \"patch\" or \"script\""
		exit 1
	fi
}

check_valid_file_path()
{
	if [ ! -f "$FILE_PATH" ]
	then
		echo -e "ERROR: File path is not valid: $FILE_PATH"
		exit 1
	fi
}

check_any_directories_exist_prior_to_multi_clone_run()
{
	ANY_DIRECTORIES_EXIST=false
	while read line; do
		REPO_NAME=`echo $line | awk '{print $1}'`
		UPSTREAM_ORG=`echo $line | awk '{print $2}'`
		BASE_BRANCH=`echo $line | awk '{print $3}'`

		if [ "$SCOPE" = "all" ] || [ "$UPSTREAM_ORG" = "$SCOPE" ]
		then
			if [ -d "$TARGET_PATH/$REPO_NAME" ]
			then
				ANY_DIRECTORIES_EXIST=true
				echo -e "ERROR: Cannot clone \"$REPO_NAME\" repo, path already exists: $TARGET_PATH/$REPO_NAME"
			fi
		fi
	done < "$SCRIPT_DIR/config/binary-addon-repos.txt"

	if [ "$ANY_DIRECTORIES_EXIST" = "true" ]
	then
		echo -e "\nERROR: At least one repo cannot be cloned, will not proceed."
		exit 1
	fi
}

check_any_directories_missing_prior_to_run()
{
	ANY_DIRECTORIES_MISSING=false
	while read line; do
		REPO_NAME=`echo $line | awk '{print $1}'`
		UPSTREAM_ORG=`echo $line | awk '{print $2}'`
		BASE_BRANCH=`echo $line | awk '{print $3}'`

		if [ "$SCOPE" = "all" ] || [ "$UPSTREAM_ORG" = "$SCOPE" ]
		then
			if [ ! -d "$TARGET_PATH/$REPO_NAME" ]
			then
				ANY_DIRECTORIES_MISSING=true
				echo -e "ERROR: Directory for \"$REPO_NAME\" repo does not exist: $TARGET_PATH/$REPO_NAME"
			fi
		fi
	done < "$SCRIPT_DIR/config/binary-addon-repos.txt"

	if [ "$ANY_DIRECTORIES_MISSING" = "true" ]
	then
		echo -e "\nERROR: At least one repo does not exist"
		exit 1
	fi
}
