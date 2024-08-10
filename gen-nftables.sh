#!/usr/bin/bash

set -ueo pipefail

PW="$1"
PORT="${2:-12345}"
HASHED="$(echo -n "$PW" | sha1sum | awk '{print $1}' | cut -c 1-32)"

cat <<EOF
table inet filter
  set knocked_v4 {
    type ipv4_addr
    counter
    timeout 1m
  }
  set knocked_v6 {
    type ipv6_addr
    counter
    timeout 1m
  }
  chain input {
    # Register knocks.
    ip protocol udp udp dport $PORT @ih,0,128 0x$HASHED counter add @knocked_v4 { ip saddr }
    ip6 nexthdr udp udp dport $PORT @ih,0,128 0x$HASHED counter add @knocked_v6 { ip6 saddr }

    # Open door to knockers.
    ip  saddr @knocked_v4 tcp dport 22 counter accept
    ip6 saddr @knocked_v6 tcp dport 22 counter accept
  }
}

#
# To do the portknocking, run:
#   echo -n "$PW" | sha1sum | cut -c 1-32 | xxd -r -p | nc -u host.example.com $PORT
EOF
