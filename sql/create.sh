#!/usr/bin/env bash
rm database.db
sqlite3 database.db ".read schema.sql"
