#!/usr/bin/env bash
set -e
set -o pipefail

TMPD="$(mktemp -d)"
function cleanup {
    rm -fr "${TMPD?}"
}
trap cleanup EXIT

echo "Dir: ${TMPD?}"
cd "${TMPD?}"
while true; do
    nc -lup 1492 -W1 | gunzip > "${TMPD?}/msg.tar"
    TODAY="$(TZ=UTC date +%Y-%m-%d)"
    tar xf msg.tar "${TODAY?}" "${TODAY?}.sig"
    for pub in /etc/portknock/*.pub; do
        if signify-openbsd -V -p "${pub?}" -m "${TODAY?}"; then
            addr="$(cat "${TODAY?}")"
            echo "Adding ${addr?}"
            nft add element inet filter temp_allow_v4 "{${addr?}}"
            break
        fi
    done
    rm -f "${TMPD?}/msg.tar" "${TMPD?}/${TODAY?}" "${TMPD?}/${TODAY?}.sig"
done
