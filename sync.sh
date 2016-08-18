#!/bin/sh
set -e
NAME=$(basename $0)
VERSION=0.1.0
AUTHOR='ek9'
LICENSE='MIT License'
DESCRIPTION="
This script allows you to do one-way synchronization of directories using rsync
to different media.

Usage:
    $NAME [SOURCE_DIR] [TARGET_DIR]

    Positional Arguments:
        SOURCE_DIR      source directory
        TARGET_DIR      target directory

    Examples:

        # sync share directory to usb media
        \$ $NAME /home/$USER/share /mnt/share
"
usage() {
    echo "$(basename $0) v$VERSION by $AUTHOR. Licensed under $LICENSE"
    echo "$DESCRIPTION"
}

sync_notify()
{
    X=$(pgrep Xorg)
    ID=$UID
    if [ "$UID" == 0 ]; then
        ID=1000
    fi
    if [ $X -gt 0 ] && [ -S "/run/user/$ID/bus" ]; then
        export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$ID/bus
        echo "$1 $2"
        notify-send -u $1 -t 10000 -a rsync "$2"
    else
        if [ "$1" == "normal" ]; then
            echo "$2"
        else
            echo "$1: $2"
        fi
    fi
}

sync_check()
{
    # Requirements check
    if [ ! -d "$2" ]; then
        sync_notify critical "Error: target directory '$2' is not available!"
        exit 1
    elif [ ! -d "$1" ]; then
        sync_notify critical "Error: source directory '$1' is not available!"
        exit 1
    fi
}

sync()
{
    BDIR="$1"
    REPOSITORY="$2"
    PREFIX=$USER
    ARCHIVE=$PREFIX-$(date +%Y-%m-%d-%H%M)

    sync_check "$BDIR" "$REPOSITORY" "user"
    sync_notify normal 'sync started'

    # Backup all of /home and /var/www except a few
    # excluded directories
    rsync -av "$1" "$2"

    if [ $? -gt 0 ]; then
        sync_notify critical "sync has failed"
    else
        sync_notify normal 'sync has finished'
    fi
}

if [ -z "$1" ] || [ -z "$2" ]; then
    usage
    exit 1
else
    sync "$1" "$2"
fi
