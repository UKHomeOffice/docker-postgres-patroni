#!/bin/sh
# Fix permissions on the given directory to allow group read/write of
# regular files and execute of directories.
chown -R postgres:postgres "${1}"
chmod -R 700 "${1}"
