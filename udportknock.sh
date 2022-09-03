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
TODAY="$(TZ=UTC date +%Y-%m-%d)"

echo "${NET?}" > "${TMPD?}/${TODAY?}"
signify-openbsd -S -s "${KEY?}" -m "${TMPD?}/${TODAY?}"
cd "${TMPD?}"
tar cf - "${TODAY?}" "${TODAY?}".sig | gzip -9 > hello.tar
nc -q0 -u "${HOST?}" "${PORT?}" < hello.tar
