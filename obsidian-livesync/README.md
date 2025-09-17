# Obsidian LiveSync

Live synchronization for Obsidian notes using CouchDB.

## Environment Variables

- `COUCHDB_USER`: CouchDB username
- `COUCHDB_PASSWORD`: CouchDB password

## Setup

1. Set `COUCHDB_USER` and `COUCHDB_PASSWORD` in `.env`
2. Run: `systemctl --user start livesync.container`