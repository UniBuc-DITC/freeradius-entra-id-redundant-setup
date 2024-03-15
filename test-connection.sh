#!/usr/bin/env bash

# Stop on errors
set -e

USERNAME="${1:-user}"
PASSWORD="${2:-pass}"

# Try to authenticate against the local FreeRADIUS instance
radtest $USERNAME $PASSWORD localhost 0 testing123
