#!/usr/bin/awk -f

BEGIN {
	#optional domain name. add here as ".mydomain"
	optionaldomain = "";
}

END {
	for (macaddress in ipaddress_array)
		printf "local-data: \"" hostname_array[macaddress]optionaldomain " IN A " ipaddress_array[macaddress] "\"\n";

	for (macaddress in ipaddress_array)
		printf "local-data-ptr: \"" ipaddress_array[macaddress] " " hostname_array[macaddress]optionaldomain "\"\n"

}

/^lease/ {
	# found the beginning of a release block
	abandonedencountered = 0; # we'll initially assume that the release hasn't been abandoned
	expired = 0; # we'll also initially assume that the release hasn't expired
	mapped_hostname = "";
	declared_hostname = "";
	hostname = "";
	macaddress = "";	

	ipaddress = $2;
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

/hardware ethernet/ {
        gsub(/;/,"");
        macaddress = $3;
}

/client-hostname/ {
	gsub(/"/, "");
	gsub(/;$/, "");
	declared_hostname = $2;
}

/\}/ {
	# this marks the end of a lease block

	# we need to evaluate the lease to see if it's valid and should be included in the output
	if (abandonedencountered + expired == 0)  {
		# now that we've determined that this appears to be a valid lease,
		# we need to decide which hostname to use (ugly hack!)

		"grep " macaddress " ./mappings.db | awk '{ print $2 }'" | getline mapped_hostname

		if (length(mapped_hostname) == 0) {
				hostname = declared_hostname;
		} else {
				hostname = mapped_hostname;
		}

		# Then we need to check to see whether it's actually the latest lease or not.
		# If a lease exists with a newer/greater enddate, then this lease should be ignored.
		
		if (macaddress in ipaddress_array) {
			# we already have a lease recorded for this hostname
			# check the lease enddate to see if this lease is newer than the one we had previously recorded
			if (enddate_array[macaddress] < enddate) {
				ipaddress_array[macaddress] = ipaddress;
				hostname_array[macaddress] = hostname;
				enddate_array[macaddress] = enddate;
			}
		}
		else
		{
			ipaddress_array[macaddress] = ipaddress;
			hostname_array[macaddress] = hostname;
			enddate_array[macaddress] = enddate;
		}
	}
}
