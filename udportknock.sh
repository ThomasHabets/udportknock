#!/usr/bin/env bash
set -e
set -o pipefail


TMPD="$(mktemp -d)"
function cleanup {
    rm -fr "${TMPD?}"
}
trap cleanup EXIT

if [[ "$4" = "" ]]; then
    echo "Usage: $0 <key.sec> <host> <port> <x.x.x.x/y>"
    exit 1
fi

KEY="$1"
HOST="$2"
PORT="$3"
NET="$4"

TIMESTAMP="$(date +%s)"

echo "${NET?} ${TIMESTAMP?}" > "${TMPD?}/hello"
signify-openbsd -q -S -s "${KEY?}" -m "${TMPD?}/hello"
SIG="$(sed 1d "${TMPD?}/hello.sig")"
echo "${NET?} ${TIMESTAMP?} ${SIG?}" | nc -q0 -u "${HOST?}" "${PORT?}"
