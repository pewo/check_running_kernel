#!/usr/bin/perl -w

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

# Deb
# kernel=        linux	/vmlinuz-4.13.0-41-generic root=/dev/mapper/xubuntu--vg-root ro  quiet splash $vt_handoff

# Redhat/6
# kernel="       kernel /vmlinuz-2.6.32-696.28.1.el6.x86_64 ro root=/dev/mapper/vg_cen"
# Redhat/7
# kernel="       linux16 /vmlinuz-3.10.0-693.21.1.el7.x86_64 root=/dev/mapper/centos_c"
#


my($grubconf) = undef;
my($search) = undef;

if ( -f "/boot/grub2/grub.cfg" ) {
	$grubconf = "/boot/grub2/grub.cfg";
	$search = "linux";
}
elsif ( -f "/boot/grub/grub.conf" ) {
	$grubconf = "/boot/grub/grub.conf";
	$search = "kernel";
}
elsif ( -f "/boot/grub/grub.cfg" ) {
	$grubconf = "/boot/grub/grub.cfg";
	$search = "linux";
}

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


my($kernel) = undef;
my(@grub);
debug("*** grub **********************************************");
if ( ! defined($grubconf) ) {
	die "Unable to find grub configuration file";
}

if ( -r $grubconf ) {
	@grub = readfile($grubconf);
}
else {
	die "Could not read $grubconf: $!";
}


foreach ( @grub ) {
	# $_="        linux	/vmlinuz-4.13.0-41-generic root=/dev/mapper/xubuntu--vg-root ro  quiet splash $vt_handoff"

	s/^\s+//;
	# $_="linux	/vmlinuz-4.13.0-41-generic root=/dev/mapper/xubuntu--vg-root ro  quiet splash $vt_handoff"

	next unless ( m/^$search/ );
	debug("Got something with $search:\n\"$_\"");

	s/^$search\w*\s+//;
	debug("Removed initial $search+space:\n\"$_\"");
	# $_="/vmlinuz-4.13.0-41-generic root=/dev/mapper/xubuntu--vg-root ro  quiet splash $vt_handoff"

	($kernel) = split(/\s+/,$_);
	debug("Extract first field:\n\"$kernel\"");
	# $kernel="/vmlinuz-4.13.0-41-generic"

	next unless ( $kernel );

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

	last;
}
die "Could not find $search in $grubconf, exiting...\n" unless ($kernel);


debug("*** version **********************************************");
my(@procver) = readfile($procver);
my($version) = shift(@procver);
debug("Retrieved version:\n\"$version\"");
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
