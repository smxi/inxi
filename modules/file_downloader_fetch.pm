#!/usr/bin/env perl
## File: file_downloader_fetch.pl
## Version: 1.0
## Date 2017-11-26
## License: GNU GPL v3 or greater
## Copyright (C) 2017 Harald Hope

use strict;
use warnings;
#use diagnostics;
use 5.008;

use File::Basename;
use File::Fetch;

sub get_file {
	my ($type, $url, $path) = @_;
	print "$path\n";
	my $dir = dirname($path);
	
	my $ff = File::Fetch->new(uri => $url);
	my $return = 0;
	my $debug = 1;
	my $where = '';
	my $output = '';
	$ff::BLACKLIST = [lynx];
	
	if ( $type eq "stdout" || $type eq "ua-stdout" ){
		print $ff->fetch( to => $output);
	}
	elsif ($type eq "spider"){
		# do nothing, just use the return value
	}
	elsif ($type eq "file"){
		$where = $ff->fetch(to => $dir);
		print "$where\n";
	}
	if ($ff->error ){
		print "Failed to connect to server/file!\n";
		print "$ff->error \n";
		$return = 1;
	}
	return $return;
}
get_file('stdout','https://github.com/smxi/inxi/raw/master/inxi', 
'/home/harald/bin/scripts/inxi/svn/branches/inxi-perl/modules/inxi.1.gz');
