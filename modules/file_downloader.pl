#!/usr/bin/env perl
## File: file_downloader.pl
## Version: 1.1
## Date 2017-12-10
## License: GNU GPL v3 or greater
## Copyright (C) 2017 Harald Hope

use strict;
use warnings;
use diagnostics;
use 5.008;

use HTTP::Tiny;

sub get_file {
	my ($type, $url, $file) = @_;
	my $response = HTTP::Tiny->new->get($url);
	my $result = 1;
	my $debug = 0;
	my $fh;
	
	if ( ! $response->{success} ){
		print "Failed to connect to server/file!\n";
		$result = 0;
	}
	else {
		if ( $debug ){
			print "$response->{success}\n";
			print "$response->{status} $response->{reason}\n";
			while (my ($key, $value) = each %{$response->{headers}}) {
				for (ref $value eq "ARRAY" ? @$value : $value) {
					print "$key: $_\n";
				}
			}
		}
		if ( $type eq "stdout" || $type eq "ua-stdout" ){
			$result = $response->{content};
		}
		elsif ($type eq "spider"){
			# do nothing, just use the return value
		}
		elsif ($type eq "file"){
			open($fh, ">", $file);
			print $fh $response->{content}; # or die "can't write to file!\n";
			close $fh;
		}
	}
	return $result;
}
get_file('stdout','https://techpatterns.com/resources/ip.php', 
'/home/harald/bin/scripts/inxi/svn/branches/inxi-perl/modules/inxi.1.gz');
