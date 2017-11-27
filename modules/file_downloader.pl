#!/usr/bin/env perl

# File: file_downloader.pl
# Version: 1.0
# Date 2017-11-25

use strict;
use warnings;
use diagnostics;
use 5.008;

use HTTP::Tiny;

sub get_file {
	my ($type, $url, $file) = @_;
	my $response = HTTP::Tiny->new->get($url);
	my $return = 0;
	my $debug = 0;
	my $fh;
	
	if ($response->{success} == 0 ){
		print "Failed to connect to server/file!\n";
		$return = 1;
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
			print "$response->{content}" if length $response->{content};
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
	return $return;
}
get_file('stdout','https://techpatterns.com/resources/ip.php', '/home/harald/bin/scripts/inxi/svn/branches/inxi-perl/modules/inxi.1.gz');
