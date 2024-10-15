#!/bin/bash

function switchBranch() {
    TGT_BRANCH="$1"

    git checkout "$TGT_BRANCH"
}

function showStatusInShortFormat() {
    git status -s
}

function findConflictingFiles() {
    SRC_BRANCH="$1"
    TGT_BRANCH="$2"

    git checkout -q "${SRC_BRANCH}"
    git checkout -q "${TGT_BRANCH}"
    # git pull origin "${TGT_BRANCH}"

    git checkout -q -b temp_merge_branch
    git merge -q "$SRC_BRANCH" 1> /dev/null

    conflicts=$(git diff --name-only --diff-filter=U)
    if [ -n "${conflicts}" ]; then
        git merge --abort
    fi
    git checkout -q "${TGT_BRANCH}"
    git branch -q -D temp_merge_branch
    echo "$conflicts"
}

function getLastAuthorOfFile() {
    BRANCH="$1"
    FILE="$2"

    git checkout -q "$BRANCH"

    git log -1 --pretty=format:"%an" "${FILE}"
}

function listAuthorsOfFilesAcrossBranches() {
    SRC_BRANCH="$1"
    TGT_BRANCH="$2"
    CONFLICTING_FILES="$3"
    echo File,${SRC_BRANCH},${TGT_BRANCH} > fileAuthors.tmp
    # echo "Conflicting files variable: [${CONFLICTING_FILES}]"
    for FILE in ${CONFLICTING_FILES}
    do
        # echo "Processing file [${FILE}]"
        src_branch_author=`getLastAuthorOfFile "${SRC_BRANCH}" "${FILE}"`
        # echo "Source branch Author: [${src_branch_author}]"
        tgt_branch_author=`getLastAuthorOfFile "${TGT_BRANCH}" "${FILE}"`
        # echo "Target branch Author: [${tgt_branch_author}]"
        echo "$FILE,${src_branch_author},${tgt_branch_author}" >> fileAuthors.tmp
    done

    cat fileAuthors.tmp | csvlook
}

branch_exists() {
  local branch_name="$1"
  
  # Check if the branch exists by using "git show-ref" and "grep"
  if git show-ref --verify --quiet "refs/heads/$branch_name"; then
    echo "Branch '$branch_name' exists."
    return 0  # Branch exists
  else
    echo "Branch '$branch_name' does not exist."
    return 1  # Branch does not exist
  fi
}
