#!/usr/bin/env bash
## ek9/shell-scripts - https://github.com/ek9/shell-scripts
## random-pass.sh
## generates a random password of supplied lenght 9 (defaults to 32
## chars)
if [ -z $1 ]; then
    L=32
else
    L=$1
fi

openssl rand -base64 $L
