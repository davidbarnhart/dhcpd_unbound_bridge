#!/bin/sh

dhcpleasesParser /var/db/dhcpd.leases | sort | uniq > /usr/local/etc/unbound/dhcp_lease_entries.conf

service unbound reload
