# PVR Scripts for automation
Used to automate PVR client addon maintenance tasks for [Kodi](https://kodi.tv)

## Pre-requisites

* `git`
* The github `gh` command
* `bash` shell
* Access token for Github with the correct permissions

## Locally run shell scripts

The scripts are numbered as per the order a maintainer would need to run them. For each type the command can be run for a single repo or a set of repos. The sets are defined as `all` repos or only those in the `kodi-pvr` org. Allowed scopes are defined in `config/pvr-scopes.txt`, note that `all` is a special scope and any other's match on the upstream org name. There is an option target-path argument to all the scripts, if omitted the current directory will be used. It is not required but all scripts assume repos are cloned and set-up by the initial script.

The full repo list can be found in `config/pvr-repos.txt`. Running any of the commands without arguments will display help text.

Default configuation values are defined in `config/config.ini`. Such values include the default branch name which is used to subsitute for `default` in `config/pvr-repos.txt`.

1. **Cloning**
    * The repo github directory must not exist for this to be successful. Repos will be set-up with the users fork as `origin` and base repo as `upstream`. The release branch (e.g. `Matrix`, `Nexus`) will tracked to the `upstream`.
2. **Creating branches**
    * Branches will be created by first checking out the default branch, pulling the latest updates before the new branch is created.
3. **Applying patches/scripts**
    * Either patches or shell scripts can be applied to repos. Note that they will always be run form the root repo directory.
4. **Pushing branches**
    * Supports regular push and also force push if needed.
5. **Creating PRs**
    * Assuming there are valid changes on the specified branch, if the PR was already created a message will be displayed.
6. **Checking PRs**
    * Will repot if PR representing the given branch has passed it checks, is still pending or has failures.
7. **Merging PRs**
    * Merge PRs stating if the operation was successful, if the PR has already been merged or if there was an error.
8. **Releasing PRs**
    * Add a changelog and release repos. Can create releases for either `minor` (features) or `micro` (fixes/languages) releases. Simply increments the exisitng version. Direct pushes the `changelog.txt` and `addon-xml.in` change to the repo. `Use with care!!!`

## Github workflow python scripts

Workflow python scripts will each have an accompanying example workflow yml file. The yml file is required to be stored in pvr add-ons GtiHub repo in the `.github/workflows` folder.

### Changelog and release

* changelog_and_release.py
* example-workflow-chglog-rls.yml
