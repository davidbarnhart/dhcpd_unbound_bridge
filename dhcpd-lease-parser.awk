#!/usr/bin/awk -f

BEGIN {
	#optional domain name. add here as ".mydomain"
	optionaldomain = "";
}

END {
	for (hostname in ipaddress_array)
		printf "local-data: \"" hostname optionaldomain " IN A " ipaddress_array[hostname] "\"\n";

	for (hostname in ipaddress_array)
		printf "local-data-ptr: \"" ipaddress_array[hostname] " " hostname optionaldomain "\"\n"

}

/^lease/ {
	# found the beginning of a release block
	abandonedencountered = 0; # we'll initially assume that the release hasn't been abandoned
	expired = 0; # we'll also initially assume that the release hasn't expired
	missinghostname = 1; # but we don't yet know the hostname of for this particular lease
	
	ipaddress = $2;

	#printf "Found ipaddress: " ipaddress "\n";
}

/\tabandoned;/ {
	abandonedencountered = 1; # we encountered the row that marks this leases as expired. we ultimately won't use this lease
}

/^[ \t]ends/ {
	gsub(/ends/, "");
	sub($1, "");
	gsub(/UTC;/, "");

	# put the lease end date into the format of epoch (in seconds)
	# using the epoch makes it easier to perform date comparisons
	"date -j -f \"%Y\/%m\/%d%H:%M:%S\" \"" $1 $2 "\" +%s" | getline enddate # FreeBSD version
	
	# do the same for the current date/time
	#"date -j +%s" | getline currentdate # FreeBSD version
	"date +%s" | getline currentdate

	if (enddate < currentdate) {
		expired = 1;
	}
}

/client-hostname/ {
	gsub(/"/, "");
	gsub(/;$/, "");
	hostname = $2;
	missinghostname = 0;
}

/\}/ {
	# this marks the end of a lease block
	# we need to evaluate the lease to see if it's valid and should be included in the output

	#printf "End of bracket reached\n";
	#printf "abandonedencountered: " abandonedencountered "\n";
	#printf "expired: " expired "\n";
	if (abandonedencountered + expired + missinghostname == 0)  {
		# now that we've determined that this appears to be a valid lease,
		# we need to check to see whether it's actually the latest lease or not.
		# If a lease exists with a newer/greater enddate, then this lease should be ignored.
		
		if (hostname in ipaddress_array) {
			# we already have a lease recorded for this hostname
			# check the lease enddate to see if this lease is newer than the one we had previously recorded
			if (enddate_array[hostname] < enddate) {
				ipaddress_array[hostname] = ipaddress;
				enddate_array[hostname] = enddate;
			}
		}
		else
		{
			ipaddress_array[hostname] = ipaddress;
			enddate_array[hostname] = enddate;
		}
	}
}
