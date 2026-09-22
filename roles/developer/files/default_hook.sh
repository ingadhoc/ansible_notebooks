#!/bin/sh

# Delegate to the repo hook keeping its arguments: commit-msg and pre-push get
# theirs from git and fail without them. --git-common-dir resolves from a
# worktree too and ignores core.hooksPath (which points at this directory);
# --path-format is avoided on purpose, it needs git 2.31.
common_dir="$(git rev-parse --git-common-dir 2>/dev/null)" || exit 0
[ -n "$common_dir" ] || exit 0
case "$common_dir" in /*) ;; *) common_dir="$(pwd)/$common_dir" ;; esac

HOOK_PATH="$common_dir/hooks/$(basename "$0")"
if [ -x "$HOOK_PATH" ]; then
    exec "$HOOK_PATH" "$@"
fi
exit 0
