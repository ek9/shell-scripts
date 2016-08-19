#!/usr/bin/env bash
## ek9/shell-scripts - https://github.com/ek9/shell-scripts
## slowrate.sh
## slowware specific program

## arguments:
## -q, --quiet              do not output any transfer information at all
## -L, --rate-limit RATE    limit transfer to RATE bytes per second
export RATE=256k
pv -t -r -a -L $RATE  | "$@"

