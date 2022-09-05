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
    read ADDR TIMESTAMP SIG <<< "$(nc -lup 1492 -W1)"
    NOW="$(date +%s)"
    AGE=$(expr $NOW - $TIMESTAMP)
    if [[ $AGE -gt 600 ]]; then
	echo "Signature too old"
    else
	echo "${ADDR?} ${TIMESTAMP}" > hello
	(echo "untrusted comment: tmp"; echo "${SIG?}") > hello.sig
	for pub in /etc/udportknock/*.pub; do
	    if signify-openbsd -V -p "${pub?}" -m "hello"; then
		echo "Adding ${ADDR?}"
		nft add element inet filter temp_allow_v4 "{${ADDR?}}"
		break
	    fi
	done
    fi
    rm -f "${TMPD?}/hello" "${TMPD?}/hello.sig"
done
