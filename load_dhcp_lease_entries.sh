#!/bin/sh

dhcpd-lease-parser.awk /var/db/dhcpd.leases | uniq -u > /usr/local/etc/unbound/dhcp_lease_entries.conf

service unbound reload
