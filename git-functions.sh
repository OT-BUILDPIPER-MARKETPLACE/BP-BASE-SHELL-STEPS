function switchBranch() {
    TGT_BRANCH=$1

    git checkout $TGT_BRANCH
}

function showStatusInShortFormat() {
    git status -s
}

function findConflictingFiles() {
    SRC_BRANCH=$1
    TGT_BRANCH=$2

    git checkout -q "${TGT_BRANCH}"
#    git pull origin ${TGT_BRANCH}

    git checkout -q temp_merge_branch
    git merge -q "$SRC_BRANCH"

    conflicts=$(git diff --name-only --diff-filter=U)
    git merge -q --abort
    git checkout -q "${TGT_BRANCH}"
    git branch -D temp_merge_branch
    echo $conflicts
}