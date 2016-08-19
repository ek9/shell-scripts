#!/usr/bin/env bash
## ek9/shell-scripts - https://github.com/ek9/shell-scripts
## backup-system.sh
## backup your system via rsync to a target directory
if [ -z $1 ] || [ ! -d "$1" ]; then
	echo "Please provide target directory as an argument"
	exit 1
fi

sudo rsync -aAXv --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} --delete /* $1
