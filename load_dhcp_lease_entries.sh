#!/bin/sh

# This script works in tandem with the "dhcpd-lease-parser.awk" script to translate the DHCP lease info from the "dhcpd" service into a form that is friendly for the "unbound" service. The aim is to detect new leases issued by "dhcpd" and then update "unbound" so that it can resolve the IP addresses issued by "dhcpd" to the appropriate hostnames.

INPUTFILE="/var/db/dhcpd.leases" # this is the default FreeBSD DHCP leases file
OUTPUTFILE="/usr/local/etc/unbound/dhcp_lease_entries.conf" # location to store the DHCP lease information so that unbound can use it
DOMAIN="" # takes the form ".domain", otherwise leave blank if not using a domain
MAPPINGSFILE="/usr/local/etc/unbound/mappings.db" # an optional file. allows mapping MAC addresses to specific hostnames

# create the following files if they don't already exist:
test -f $OUTPUTFILE || touch $OUTPUTFILE # just in case this is the very first time and the file doesn't exist yet (to avoid the "stat" command below from throwing an error)
test -f $MAPPINGSFILE || touch $MAPPINGSFILE

# get various file metadata properties (helps to detect whether it's time to parse the leases yet)
INPUTFILE_LASTMODIFIED=$(stat -f %m $INPUTFILE) 
OUTPUTFILE_LASTMODIFIED=$(stat -f %m $OUTPUTFILE) 
MAPPINGSFILE_LASTMODIFIED=$(stat -f %m $MAPPINGSFILE)
OUTPUTFILE_SIZE=$(stat -f %z $OUTPUTFILE)

# if something recently changes, regenerate the "unbound" leases file and force "unbound" to reload the list
if [ $INPUTFILE_LASTMODIFIED -gt $OUTPUTFILE_LASTMODIFIED ] || [ $MAPPINGSFILE_LASTMODIFIED -gt $OUTPUTFILE_LASTMODIFIED ] || [ $OUTPUTFILE_SIZE -eq 0 ]; then 
	dhcpd-lease-parser.awk -v DOMAIN=$DOMAIN -v MAPPINGSFILE=$MAPPINGSFILE $INPUTFILE | uniq -u > $OUTPUTFILE
	service unbound reload
fi 
