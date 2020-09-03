## dhcpd_unbound_bridge
AWK script to parse DHCP leases handed out by isc-dhcp and parse them into a format readable by unbound

### How to install (suggested):

1. Place the dhcpd-lease-parser.awk script somewhere like /usr/local/sbin and make sure it's executable (chmod 755)
2. Place the load_dhcp_lease_entries.sh script in the same directory as the unbound configuration files (e.g. /usr/local/etc/unbound/) and make sure it's also executable.
3. Edit the unbound configuration file (e.g. /usr/local/etc/unbound/unbound.conf) and add an include line to the parsed file that is created by the load_dhcp_lease_entries.sh script (e.g. include "/usr/local/etc/unbound/dhcp_lease_entries.conf")
4. Add a cron job for root to execute the bash script every five minutes, which refreshes the parsed leases files and reloads unbound: */5     *       *       *       *       "/usr/local/etc/unbound/load_dhcp_lease_entries.sh"


### Background

Having used pfSense for years, I decided to try my hand at rolling my own FreeBSD-based router. I used the dhcpd port from OpenBSD (/usr/ports/net/dhcpd) and chose to go with unbound as my DNS resolver just for simplicity. This is a common configuration within pfSense and opnSense. Both of those platforms include an option to register the hostname from dhcpd leases within the unbound DNS config. This frees you from using IP addresses to reference local machines instead of IP addresses.

Unfortunately I couldn't find an out-of-the-box method for taking the info from these dhcpd leases and registering it with unbound. After studying both pfSense and opnSense, I realized that this functionality is handled by some additional scripts unique to each project. Typically there is a file watcher on the dhcpd lease file, which kicks off some additional parsing scripts each time the file is modified. opnSense seemed like it was using Python-based scripts, while pfSense seemed to be relying on a much older Perl script. I thought about installing Python on my router but wanted to avoid that if possible.

I found a couple other projects that offered some level of support for parsing dhcp leases and registering them with unbound. However, each required some sort of dependency that I didn't really want. That's when I eventually decided to skip the file watcher (again for simplicity) and handle the parsing with a combination of awk and sh.

The awk script does the majority of the work, trying to parse valid leases (throwing out adandoned or expired leases). The shell script uses this awk script to read in the dhcpd leases file and output a file that is suitable for unbound. At that point, you just need to tell unbound to include the parsed file and reload the unbound config each time the parsed file is updated. I added a cron job to kick this off every five minutes, which seemed about good enough.
