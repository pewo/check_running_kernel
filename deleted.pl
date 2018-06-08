#!/usr/bin/perl -w

use strict;


my($pid);
foreach $pid ( </proc/*> ) {
	my($fd) = $pid . "/map_files";
	next unless ( -d $fd );
	my(@arr) = ();
	foreach ( <$fd/*> ) {
		next unless ( -l $_ );
		my($dest) = readlink($_);
		next unless ( defined($dest) );
		next if ( $dest =~ /\/dev\// );
		next if ( $dest =~ /cache/ );
		next if ( $dest =~ /\/run\// );
		next if ( $dest =~ /\/home\// );
		if ( $dest =~ /(\s+\(.*\))/ ) {
			$dest =~ s/\s+\(.*\)//;
			next unless ( -r $dest );
			push(@arr,$dest);
		}
	}
	if ( $#arr >= 0 ) {
		my($cmdline) = "$pid/cmdline";
		next unless ( -r $cmdline );
		next unless ( open(IN,"<$cmdline") );
		my($cmd) = <IN>;
		print "***\n$cmd $pid \n";
		foreach ( @arr ) {
			print "\t$_\n";
		}
	}
}
