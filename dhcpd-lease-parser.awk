{
	#optional domain name. add here as ".mydomain"
	optionaldomain = "";
}

#{ print; }

/^lease/ {
	abandonedencountered = 0;
	expired = 0;
	missinghostname = 1;
	
	ipaddress = $2;
}

/\tabandoned;/ {
	abandonedencountered = 1;
}

/^[ \t]ends/ {
	gsub(/ends/, "");
	sub($1, "");
	gsub(/UTC;/, "");
	"date -j -f \"%Y\/%m\/%d%H:%M:%S\" \"" $1 $2 "\" +%s" | getline enddate
	# the enddate variable represet the epoch (in seconds) that the lease expired

	"date -j +%s" | getline currentdate

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
	#printf "End of bracket reached\n";
	#printf "abandonedencountered: " abandonedencountered "\n";
	#printf "expired: " expired "\n";
	if (abandonedencountered + expired + missinghostname == 0)  {
		printf "local-data: \"" hostname optionaldomain " IN A " ipaddress "\"\n"
		printf "local-data-ptr: \"" ipaddress " " hostname optionaldomain "\"\n"
	}
}
