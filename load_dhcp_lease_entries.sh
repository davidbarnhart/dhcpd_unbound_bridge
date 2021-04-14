#!/bin/sh

INPUTFILE="/var/db/dhcpd.leases"
OUTPUTFILE="/usr/local/etc/unbound/dhcp_lease_entries.conf"

INPUTFILE_LASTMODIFIED=$(stat -f %m $INPUTFILE) 
OUTPUTFILE_LASTMODIFIED=$(stat -f %m $OUTPUTFILE) 

if [ $INPUTFILE_LASTMODIFIED -gt $OUTPUTFILE_LASTMODIFIED ]; then 
	dhcpd-lease-parser.awk $INPUTFILE | uniq -u > $OUTPUTFILE
	service unbound reload
fi 
