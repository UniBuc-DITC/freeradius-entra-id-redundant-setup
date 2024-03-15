#!/usr/bin/env bash

set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE TABLE failed_logins (
        id integer PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
        username text NOT NULL CHECK (username <> ''),
        time timestamptz NOT NULL
    );
    CREATE INDEX failed_logins_username_index ON failed_logins (username);
EOSQL
