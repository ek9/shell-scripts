#!/usr/bin/env bash
## ek9/shell-scripts - https://github.com/ek9/shell-scripts
## chmod-dirs.sh
# Find all dirs in current directory and chmods them according to provided
# argument
NEWMOD=$1

if [ -z $NEWMOD ]; then
    echo "chmod-dirs: Please provide an argument to chmod with (e.g. 755)"
    exit 1;
fi

find . -type d -exec chmod $NEWMOD {} \;

exit 0

