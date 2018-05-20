#!/usr/bin/perl -w

use strict;
my($debug) = 1;

# tested ok on swift: DISTRIB_DESCRIPTION="Ubuntu 16.04.4 LTS"
# tested ok on dev: DISTRIB_DESCRIPTION="Linux Mint 18.1 Serena"

# kernel=        linux	/vmlinuz-4.13.0-41-generic root=/dev/mapper/xubuntu--vg-root ro  quiet splash $vt_handoff
my($grubconf) = "/boot/grub/grub.cfg";

# version=Linux version 4.13.0-41-generic (buildd@lgw01-amd64-028) (gcc version 5.4.0 20160609 (Ubuntu 5.4.0-6ubuntu1~16.04.9)) #46~16.04.1-Ubuntu SMP Thu May 3 10:06:43 UTC 2018
my($procver) = "/proc/version";

sub debug($) {
	return unless ( $debug );
	my($str) = shift;
	chomp($str);
	print "DEBUG: $str\n";
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
		push(@res,$_);
	}
	close(IN);
	return(@res);
}


my($kernel) = undef;
my(@grub) = readfile($grubconf);
foreach ( @grub ) {
	# $_="        linux	/vmlinuz-4.13.0-41-generic root=/dev/mapper/xubuntu--vg-root ro  quiet splash $vt_handoff"

	s/^\s+//;
	# $_="linux	/vmlinuz-4.13.0-41-generic root=/dev/mapper/xubuntu--vg-root ro  quiet splash $vt_handoff"

	next unless ( m/^linux\s+/ );
	debug("Got something with linux: \"$_\"");

	s/^linux\s+//;
	debug("Removed initial linux+space: \"$_\"");
	# $_="/vmlinuz-4.13.0-41-generic root=/dev/mapper/xubuntu--vg-root ro  quiet splash $vt_handoff"

	($kernel) = split(/\s+/,$_);
	debug("Extract first field: \"$kernel\"");
	# $kernel="/vmlinuz-4.13.0-41-generic"

	next unless ( $kernel );

	$kernel =~ s/^\D+-//;
	debug("Removed starting characters: \"$kernel\"");
	# $kernel="/4.13.0-41-generic"
	
	$kernel =~ s/-\D+$//;
	debug("Removed ending characters: \"$kernel\"");
	# $kernel="4.13.0-41"

	last;
}
die "Could not find kernel in $grubconf, exiting...\n" unless ($kernel);


my(@procver) = readfile($procver);
my($version) = shift(@procver);
debug("Retrieved version: \"$version\"");
# version=Linux version 4.13.0-41-generic (buildd@lgw01-amd64-028) (gcc version 5.4.0 20160609 (Ubuntu 5.4.0-6ubuntu1~16.04.9)) #46~16.04.1-Ubuntu SMP Thu May 3 10:06:43 UTC 2018

$version =~ s/^\D+//;
debug("Removed starting characters: \"$version\"");
# version=4.13.0-41-generic (buildd@lgw01-amd64-028) (gcc version 5.4.0 20160609 (Ubuntu 5.4.0-6ubuntu1~16.04.9)) #46~16.04.1-Ubuntu SMP Thu May 3 10:06:43 UTC 2018

($version) = split(/\s/,$version);
debug("Extract first field: \"$version\"");
# version=4.13.0-41-generic 

$version =~ s/-\D+$//;
debug("Removed ending characters: \"$version\"");
# version=4.13.0-41 

if ( $version =~ /$kernel/ ) {
	print "Running latest($kernel) installed kernel\n";
}
else {
	print "Running old($version) instead of running latest($kernel) installed kernel\n";
}
