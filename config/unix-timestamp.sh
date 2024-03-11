#!/usr/bin/env bash

# This script is used to convert a datetime string in C locale to a UNIX timestamp,
# to avoid issues when deserializing it from the Redis-based cache.
# TODO: get rid of this workaround once https://github.com/FreeRADIUS/freeradius-server/issues/5304 gets fixed

set -e

date -d "$1" +%s
