#!/usr/bin/env bash
## ek9/shell-scripts - https://github.com/ek9/shell-scripts
## reflector-fetch.sh
## fetches latest and fastest https mirrors for archlinux system
sudo reflector -p https --sort score -a 12 --latest 32 --fastest 16 --save /etc/pacman.d/mirrorlist
