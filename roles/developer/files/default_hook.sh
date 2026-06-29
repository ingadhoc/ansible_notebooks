#!/bin/sh

HOOK_PATH="$(pwd)/.git/hooks/$(basename "$0")"
if [ -x "$HOOK_PATH" ]; then
    exec "$HOOK_PATH"
fi
