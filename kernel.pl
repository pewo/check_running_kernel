#!/usr/bin/perl -w

#
# Date: Sat Sep 22 18:12:10 CEST 2018
#
use strict;
my($debug) = 0;
my($arg) = shift(@ARGV);

if ( defined($arg) ) {
	$debug = 1;
}

# tested ok on swift: DISTRIB_DESCRIPTION="Ubuntu 16.04.4 LTS"
# tested ok on dev: DISTRIB_DESCRIPTION="Linux Mint 18.1 Serena"
# tested ok on centos6: CentOS release 6.9 (Final)
# tested ok on centos7: CentOS Linux release 7.4.1708 (Core) 
# tested ok on Arch: by pebe
# tested ok on Fedora Rawhide: by pebe
# tested ok on CentOS 7.5: by pebe
# tested ok on Raspbian: by pebe
# Does not report anythin useful on solaris: by pewo
#

# version=Linux version 4.13.0-41-generic (buildd@lgw01-amd64-028) (gcc version 5.4.0 20160609 (Ubuntu 5.4.0-6ubuntu1~16.04.9)) #46~16.04.1-Ubuntu SMP Thu May 3 10:06:43 UTC 2018
my($procver) = "/proc/version";



sub debug($) {
	return unless ( $debug );
	my($str) = shift;
	chomp($str);
	print "\nDEBUG: $str\n";
}


sub readfile($) {
	my($file) = shift;

	debug("Reading file $file");
	unless ( open(IN,"<$file") ) {
		die "Reading $file: $!\n";
	}

	my(@res) = ();
	foreach ( <IN> ) {
		chomp;
		push(@res,sprintf("%-70.70s",$_));
	}
	close(IN);
	return(@res);
}

sub modules {
	my($dir) = "/lib/modules";
	my(@dir) = ();
	if ( -d $dir ) {
		foreach ( <$dir/*> ) {
			my(@arr) = split(/\//,$_);
			my($kernel) = $arr[-1];
			next unless ( $kernel =~ /^\d/ );
			push(@dir,$kernel);
			debug("Adding $kernel to list of kernels");
		}
	}
	return(@dir);
}

sub modsort {
	my(@a) = split(/\D+/,$a);
	my($astr) = join(" ","a:", @a, "\n");
	debug("Sorting(a) $astr");
	my(@b) = split(/\D+/,$b);
	my($bstr) = join(" ","b:", @b, "\n");
	debug("Sorting(b) $bstr");
	my($sa);
	foreach $sa ( @a ) {
		my($sb) = shift(@b);
		return(-1) unless ( defined($sb) );
		my($diff ) = $sb <=> $sa;
		if ( $diff ) {
			return($diff);
		}
	}
	return(0);
}
	
sub latestmod() {
	my(@mod) = modules();
	if ( $#mod >= 0 ) {
		debug("Sorting list of kernels");
		my(@res) = sort modsort @mod;
		return(shift(@res));
	}
	else {
		return(undef);
	}
}

#
# Check if container, this must be improved...
#
if ( -f "/proc/user_beancounters" ) {
	print "Unsupported system (container or openvz server)\n";
	exit 0;
}


my($kernel) = undef;

debug("*** installed **********************************************");
$kernel = latestmod();
unless ( $kernel ) {
	print "Unsupported system (kernel)\n";
	exit 0;
}
	
debug("Latest kernel is $kernel");


$kernel =~ s/^\D+-//;
debug("Removed starting characters:\n\"$kernel\"");
# $kernel="4.13.0-41-generic"
# $kernel="2.6.32-696.28.1.el6.x86_64"

	
if ( $kernel =~ /-\D+$/ ) {
	$kernel =~ s/-\D+$//;
	debug("Removed ending characters:\n\"$kernel\"");
	# $kernel="4.13.0-41"
}
elsif ( $kernel =~ /\.\D+/ ) {
	$kernel =~ s/\.\D+.*$//;
	debug("Removed ending characters:\n\"$kernel\"");
	# "2.6.32-696.28.1"
}


debug("*** version **********************************************");
my(@procver) = readfile($procver);
unless ( $#procver >= 0 ) {
	print "Unsupported system (version)\n";
	exit 0;
}

my($version) = shift(@procver);
debug("Running kernel is $version");
# version=Linux version 4.13.0-41-generic (buildd@lgw01-amd64-028) (gcc version 5.4.0 20160609 (Ubuntu 5.4.0-6ubuntu1~16.04.9)) #46~16.04.1-Ubuntu SMP Thu May 3 10:06:43 UTC 2018

$version =~ s/^\D+//;
debug("Removed starting characters:\n\"$version\"");
# version=4.13.0-41-generic (buildd@lgw01-amd64-028) (gcc version 5.4.0 20160609 (Ubuntu 5.4.0-6ubuntu1~16.04.9)) #46~16.04.1-Ubuntu SMP Thu May 3 10:06:43 UTC 2018

($version) = split(/\s/,$version);
debug("Extract first field:\n\"$version\"");
# version=4.13.0-41-generic 

$version =~ s/-\D+$//;
debug("Removed ending characters:\n\"$version\"");
# version=4.13.0-41 

debug("*** result **********************************************");
if ( $version =~ /$kernel/ ) {
	print "Running latest installed kernel($kernel)\n";
	exit 0;
}
else {
	print "Running old kernel($version) instead of latest installed kernel($kernel)\n";
	exit 1;
}
