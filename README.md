# UDPortknock

Becuase modulating a password over SYN packets is stupid.

## Guide

### Dependency (server and client): signify (from openbsd)

```
apt install signify-openbsd
```

### Set up server

#### Server step 1: Create firewall with hooks

Example `/etc/nftables.conf`.

```
table inet filter {
  set temp_allow_v4 {
    type ipv4_addr
	flags interval
	counter
	timeout 10m
  }
  chain input {
    type filter hook input priority 0; policy drop;
	ct state established counter accept comment "Allow already established"
    ct state related counter accept comment "Allow related, incl ICMP errors"
    ct state invalid counter drop   comment "Drop invalid packets"
	
    iifname lo counter accept comment "Allow everything on loopback"
    ip6 daddr ff02::1 counter accept comment "Allow stuff like router advertisment"

	udp port 1492 counter accept comment "Allow portknocks"
	ip sadd @temp_allow_v4 jump trusted comment "Allow hosts that have portknocked"
	counter comment "Count dropped packets"
  }
  chain trusted {
    tcp dport  22 counter accept comment "Allow SSH"
	tcp dport  80 counter accept comment "Allow HTTP"
	tcp dport 443 counter accept comment "Allow HTTPS"
  }
}
```

#### Server step 2: Load config

```
nft -f /etc/nftables.conf
```

#### Server step 3: Start udportknockd

```
mkdir /etc/udportknock
./udportknockd.sh
```

(TODO: create a systemd conf)

### Set up client

#### Create key

```
signify-openbsd -G -p client.pub -s client.sec
```

#### Copy pub key to server (only .pub file)

In server's `/etc/udportknock/`.

#### Use udportknock client to get access to server

```
./udportknock.sh client.sec server.example.com 1492 $(curl ifconfig.me)
```
