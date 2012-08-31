#!/usr/bin/env bash
rm -f database.db
sqlite3 database.db ".read schema.sql"
