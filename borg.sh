#!/usr/bin/env bash
## ek9/shell-scripts - https://github.com/ek9/shell-scripts
## borg.sh
# TODO Adapt according to https://gist.github.com/mqu/80330005b961ca93e0d7
set -e
NAME=$(basename $0)
VERSION=0.1.0
AUTHOR='ek9'
LICENSE='MIT License'
DESCRIPTION="
This script allows you to backup your system using borg backup. It supports
two backup modes:
* System backup - used for backing up systems (excluding home directories).
* Home backup - used for backing up home directories.

Usage:
    $NAME [--home/--system] [DIRECTORY] [BACKUP_REPO]

    Exclusive arguments:
        --home          used for backing up home directories (e.g. /home/$USER)
        --system        used for backing up systems (excluding /home)
        --full          used for backing up full systems
        --remote        used for backing up home to remote storage via SSH

    Positional Arguments:
        DIRECTORY       base directory to backup
        BACKUP_REPO     backup repository (for storing backups)

    Examples:

        # backup home directory of current user to /mnt/backup/$USER
        \$ $NAME --home /home/$USER /mnt/backup1/$USER

        # backup system (excluding home directories) to /mnt/backup/system
        \$ $NAME --system / /mnt/backup1/system

        # backup system mounted on /media/system to /mnt/backup/system
        \$ $NAME --system /media/system /mnt/backup1/system

        # backup full system to /mnt/backup2/systemm
        \$ $NAME --full / /mnt/backup2/system

        # backup home directory to a remote server (via SSH)
        \$ $NAME --remote /home/$USER user@example:borg/$USER
"

usage() {
    echo "$(basename $0) v$VERSION by $AUTHOR. Licensed under $LICENSE"
    echo "$DESCRIPTION"
}

backup_notify()
{
    X=$(pgrep Xorg)
    ID=$UID
    if [ "$UID" == 0 ]; then
        ID=1000
    fi
    if [ $X -gt 0 ] && [ -S "/run/user/$ID/bus" ]; then
        export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$ID/bus
        echo "$1 $2"
        notify-send -u $1 -t 2000 -a borg "$2"
    else
        if [ "$1" == "normal" ]; then
            echo "$2"
        else
            echo "$1: $2"
        fi
    fi
}

backup_check()
{
    if [ ! -d "$1" ]; then
        backup_notify critical "Error: directory '$1' is not available!"
        exit 1
    elif [ -z "$BORG_PASSPHRASE" ]; then
        backup_notify critical "Error: BORG_PASSPHRASE environment variable is not set!"
        exit 1
    fi

    if [ "$3" != "home" ]; then
        borg check --repository-only "$2"
        if [ $? -gt 0 ]; then
            backup_notify critical "Error: '$2' is not a valid repository!"
            exit 1
        fi
    fi
}

backup_home()
{
    if [ "$HOME" != "$1" ]; then
        root_required
    fi

    backup_notify normal 'backup: home started'
    BDIR="$1"
    REPOSITORY="$2"
    PREFIX=$USER
    ARCHIVE=$PREFIX-$(date +%Y-%m-%d-%H%M)

    backup_check "$BDIR" "$REPOSITORY" home

    # Backup all of /home and /var/www except a few
    # excluded directories
    borg create -v --stats --compression zlib,7 --umask 0027       \
        "$REPOSITORY::$ARCHIVE"                         \
        "$BDIR"                                         \
        --exclude "$BDIR/.cache"                        \
        --exclude "$BDIR/.local/share/Steam"            \
        --exclude "$BDIR/.local/share/Trash"            \
        --exclude "$BDIR/.local/share/vagrant"          \
        --exclude "$BDIR/archive"                       \
        --exclude "$BDIR/inbox"                         \
        --exclude "$BDIR/projects/kapma"                \
        --exclude "$BDIR/share"                         \
        --exclude "$BDIR/tmp"                           \
        --exclude "$BDIR/var/vbox"

    if [ $? -gt 0 ]; then
        backup_notify critical "backup: home failed"
    fi

    # Use the `prune` subcommand to maintain 7 daily, 4 weekly and 6 monthly
    # archives of THIS machine. --prefix `hostname`- is very important to
    # limit prune's operation to this machine's archives and not apply to
    # other machine's archives also.
    borg prune "$REPOSITORY" --prefix "${PREFIX}"- --umask 0027 \
        --keep-hourly=24 --keep-daily=7 --keep-weekly=4 --keep-monthly=12 \
        --keep-yearly=3

    backup_notify normal 'backup: home finished'
}

backup_system()
{
    root_required
    BDIR="$1"
    REPOSITORY="$2"
    PREFIX=$(hostname)
    ARCHIVE=$PREFIX-$(date +%Y-%m-%d-%H%M)

    backup_check "$BDIR" "$REPOSITORY"

    backup_notify normal 'backup: system started'

    borg create -v --stats --compression zlib,7 --umask 0027 \
        "$REPOSITORY::$ARCHIVE"                            \
        "$BDIR"                                            \
        --exclude /dev                                     \
        --exclude /proc                                    \
        --exclude /sys                                     \
        --exclude /home                                    \
        --exclude /tmp                                     \
        --exclude /run                                     \
        --exclude /mnt                                     \
        --exclude /media                                   \
        --exclude /lost+found

    if [ $? -gt 0 ]; then
        backup_notify critical "backup: system failed"
    fi

    # Use the `prune` subcommand to maintain 7 daily, 4 weekly and 6 monthly
    # archives of THIS machine. --prefix `hostname`- is very important to
    # limit prune's operation to this machine's archives and not apply to
    # other machine's archives also.
    borg prune "$REPOSITORY" --prefix "${PREFIX}-" --umask 0027 \
        --keep-daily=31 --keep-weekly=12 --keep-monthly=12 --keep-yearly=3

    backup_notify normal 'backup: system finished'

}


backup_full()
{
    root_required
    backup_notify normal 'backup: system started'
    BDIR="$1"
    REPOSITORY="$2"
    PREFIX=$(hostname)
    ARCHIVE=$PREFIX-$(date +%Y-%m-%d-%H%M)

    backup_check "$BDIR" "$REPOSITORY"

    borg create -v --stats --compression zlib,7 --umask 0027 \
        $REPOSITORY::$ARCHIVE                           \
        $BDIR                                           \
        --exclude /dev                                  \
        --exclude /proc                                 \
        --exclude /sys                                  \
        --exclude 'sh:/home/*/.cache'                   \
        --exclude 'sh:/home/*/.local/share/Steam'       \
        --exclude 'sh:/home/*/.local/share/Trash'       \
        --exclude 'sh:/home/*/.local/share/vagrant'     \
        --exclude 'sh:/home/*/archive'                  \
        --exclude 'sh:/home/*/inbox'                    \
        --exclude 'sh:/home/*/projects/kapma'           \
        --exclude 'sh:/home/*/share'                    \
        --exclude 'sh:/home/*/tmp'                      \
        --exclude 'sh:/home/*/var/vbox'                 \
        --exclude /tmp                                  \
        --exclude /run                                  \
        --exclude /mnt                                  \
        --exclude /media                                \
        --exclude /lost+found

    if [ $? -gt 0 ]; then
        backup_notify critical "backup: system failed"
    fi

    # Use the `prune` subcommand to maintain 7 daily, 4 weekly and 6 monthly
    # archives of THIS machine. --prefix `hostname`- is very important to
    # limit prune's operation to this machine's archives and not apply to
    # other machine's archives also.
    borg prune "$REPOSITORY" --prefix "${PREFIX}"- --umask 0027 \
        --keep-daily=7 --keep-weekly=4 --keep-monthly=12 --keep-yearly=3

    backup_notify normal 'backup: system finished'

}

backup_remote()
{
    if [ "$HOME" != "$1" ]; then
        root_required
    fi

    eval "$(keychain --eval)"
    backup_notify normal 'backup: home started'
    BDIR="$1"
    REPOSITORY="$2"
    PREFIX=$USER
    ARCHIVE=$PREFIX-$(date +%Y-%m-%d-%H%M)

    backup_check "$BDIR" "$REPOSITORY"

    # Backup all of /home and /var/www except a few
    # excluded directories
    borg create -v --stats --compression zlib,7 --umask 0027       \
        "$REPOSITORY::$ARCHIVE"                         \
        "$BDIR"                                         \
        --exclude "$BDIR/.cache"                        \
        --exclude "$BDIR/.local/share/Steam"            \
        --exclude "$BDIR/.local/share/Trash"            \
        --exclude "$BDIR/.local/share/vagrant"          \
        --exclude "$BDIR/archive"                       \
        --exclude "$BDIR/inbox"                         \
        --exclude "$BDIR/projects/kapma"                \
        --exclude "$BDIR/share"                         \
        --exclude "$BDIR/tmp"                           \
        --exclude "$BDIR/var/vbox"

    if [ $? -gt 0 ]; then
        backup_notify critical "backup: system failed"
    fi

    # Use the `prune` subcommand to maintain 7 daily, 4 weekly and 6 monthly
    # archives of THIS machine. --prefix `hostname`- is very important to
    # limit prune's operation to this machine's archives and not apply to
    # other machine's archives also.
    borg prune "$REPOSITORY" --prefix "${PREFIX}"- --umask 0027 \
        --keep-hourly=24 --keep-daily=7 --keep-weekly=4 --keep-monthly=12 \
        --keep-yearly=3

    backup_notify normal 'backup: remote finished'
}

root_required() {
# check if we are running as root
if [ ! "$UID" -eq 0 ]; then
    backup_notify critical "Error: root privileges are required to backup $0"
    exit 1
fi
}

export BORG_PASSPHRASE="$BORG_PASSPHRASE"
export BORG_RSH='slowrate.sh ssh'

if [ "$1" == '--home' ]; then
    backup_home "$2" "$3"
elif [ "$1" == '--system' ]; then
    backup_system "$2" "$3"
elif [ "$1" == '--full' ]; then
    backup_full "$2" "$3"
elif [ "$1" == '--remote' ]; then
    backup_remote "$2" "$3"
else
    usage
    exit 1
fi
