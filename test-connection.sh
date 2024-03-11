#!/usr/bin/env bash

# Stop on errors.
set -e

# Test the RADIUS authentication.
radtest user test localhost 0 testing123
