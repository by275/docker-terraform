#!/bin/sh
set -e

if [ $TF_AUTO_RUN -ne 0 ]; then
    terraform.sh
    exit $?
fi

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
    set -- terraform "$@"
fi

# if our command is a valid Terraform subcommand, let's invoke it through Terraform instead
# (this allows for "docker run terraform version", etc)
if terraform "$1" -help >/dev/null 2>&1 ; then
    set -- terraform "$@"
fi

exec "$@"
