#!/usr/bin/env bash
set -e

install_lock="${SOURCE_PATH}/.install"

echo "Cleaning up..."

# Remove install lock  to avoid neverending install after crash
if [ -f "${install_lock}" ]
then
    echo "Removing install lock"
    rm -f "${install_lock}"
fi

echo "Clean up done."
