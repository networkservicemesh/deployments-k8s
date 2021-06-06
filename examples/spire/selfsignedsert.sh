#!/bin/bash

if [ ! -x "$(command -v openssl)" ]; then
    echo "openssl not found"
    exit 1
fi

if [ -f "$1/bootstrap.key" ]; then
    echo "key file exits."
    exit 0
fi

echo "creating certs in $1"

openssl req -x509 -newkey rsa:4096 -keyout "$1/bootstrap.key" -out "$1/bootstrap.crt" -days 365 -nodes -subj '/CN=localhost'

exit 0