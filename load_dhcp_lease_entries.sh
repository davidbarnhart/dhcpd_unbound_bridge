#!/bin/sh

dhcpd-lease-parser.awk /var/db/dhcpd.leases | sort | uniq > /usr/local/etc/unbound/dhcp_lease_entries.conf

service unbound reload
