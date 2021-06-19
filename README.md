## dhcpd_unbound_bridge
awk script to parse DHCP leases handed out by the ISC DHCP server and parse them into a format readable by unbound. Original written by @davidbarnhart, adapter by @robdejonge to use explicit hostnames. 

### How to install (suggested):

1. Place the dhcpd-lease-parser.awk script somewhere like /usr/local/sbin and make sure it's executable (chmod 755)
2. Place the load_dhcp_lease_entries.sh script in the same directory as the unbound configuration files (e.g. /usr/local/etc/unbound/) and make sure it's also executable.
3. (optional) Enter your mappings into the mappings.db file (which is just a text file) in a `MA:CA:DD:RE:SS myhostname` format (note the space).
4. Edit the unbound configuration file (e.g. /usr/local/etc/unbound/unbound.conf) and add an include line to the parsed file that is created by the load_dhcp_lease_entries.sh script (e.g. `include "/usr/local/etc/unbound/dhcp_lease_entries.conf"`)
5. Add a cron job for root to execute the bash script every five minutes, which refreshes the parsed leases files and reloads unbound: */5	*	*	*	*	root	/usr/local/etc/unbound/load_dhcp_lease_entries.sh

Note that an alternative to the cron job would be to leverage the ISC DHCP server's ability to execute a command each time a lease is handed out: https://jpmens.net/2011/07/06/execute-a-script-when-isc-dhcp-hands-out-a-new-lease/


### Background by @davidbarnhart

Having used pfSense for years, I decided to try my hand at rolling my own FreeBSD-based router. I used the dhcpd port from OpenBSD (/usr/ports/net/dhcpd) and chose to go with unbound as my DNS resolver just for simplicity. This is a common configuration within pfSense and OPNsense. Both of those platforms include an option to register the hostname from dhcpd leases within the unbound DNS config. This lets you use hostnames to reference local machines instead of IP addresses. Basic stuff, or at least I thought.

Unfortunately I couldn't find an out-of-the-box method for taking the info from these dhcpd leases and registering the IP address/hostname combinations with unbound. After studying both pfSense and OPNsense, I realized that this functionality is handled by some additional scripts unique to each project. Typically there is a file watcher on the dhcpd lease file, which kicks off some additional parsing scripts each time the file is modified. OPNsense seemed like it was using Python-based scripts, while pfSense seemed to be relying on a much older Perl script. I thought about installing Python on my router but wanted to avoid that if possible.

I found a couple other projects that offered some level of support for parsing dhcp leases and registering them with unbound. However, each required some sort of dependency that I didn't really want. That's when I eventually decided to skip the file watcher (again for simplicity) and handle the parsing with a combination of awk and sh - tools that ship with every FreeBSD system.

The awk script does the majority of the work, trying to parse valid leases (throwing out adandoned or expired leases). The shell script uses this awk script to read in the dhcpd leases file and output a file that is suitable for unbound. At that point, you just need to tell unbound to include the parsed file and reload the unbound config each time the parsed file is updated. I added a cron job to kick this off every five minutes, which seemed about good enough.


### Modification by @robdejonge

Instead of using the `client-hostname` directive from the `dhcpd.leases` file, I needed a way to use explicit hostnames so that whatever each host tells `dhcpd` can be ignored and entries in `unbound` are the way I want them to be. Some devices can't be configured to use a sensible hostname, and the non-sensical ones can be hard to recall! The script will now search `mappings.db` for a match (that part admittedly an ugly hack!), and if one is found use that as the overriding hostname for the output. 
