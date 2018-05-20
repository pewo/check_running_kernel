#!/usr/bin/perl -w

use strict;

# tested ok on swift: DISTRIB_DESCRIPTION="Ubuntu 16.04.4 LTS"
# kernel=        linux	/vmlinuz-4.13.0-41-generic root=/dev/mapper/xubuntu--vg-root ro  quiet splash $vt_handoff
my($grubconf) = "/boot/grub/grub.cfg";

# version=Linux version 4.13.0-41-generic (buildd@lgw01-amd64-028) (gcc version 5.4.0 20160609 (Ubuntu 5.4.0-6ubuntu1~16.04.9)) #46~16.04.1-Ubuntu SMP Thu May 3 10:06:43 UTC 2018
my($procver) = "/proc/version";

sub readfile($) {
	my($file) = shift;

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
	s/^linux\s+//;
	# $_="/vmlinuz-4.13.0-41-generic root=/dev/mapper/xubuntu--vg-root ro  quiet splash $vt_handoff"

	($kernel) = split(/\s+/,$_);
	# $kernel="/vmlinuz-4.13.0-41-generic"

	next unless ( $kernel );

	$kernel =~ s/^\D+-//;
	# $kernel="/4.13.0-41-generic"
	
	$kernel =~ s/-\D+$//;
	# $kernel="4.13.0-41"

	print "DEBUG: kernel=$kernel\n";
	last;
}
die "Could not find kernel in $grubconf, exiting...\n" unless ($kernel);


my(@procver) = readfile($procver);
my($version) = shift(@procver);

print "version=$version\n";
print "kernel=$kernel\n";

if ( $version =~ /$kernel/ ) {
	print "Running latest($kernel) installed kernel\n";
}
else {
	print "Not running latest($kernel) installed kernel\n";
}
