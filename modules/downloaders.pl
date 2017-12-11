#!/usr/bin/env perl
## File: file_downloader.pl
## Version: 1.1
## Date 2017-12-10
## License: GNU GPL v3 or greater
## Copyright (C) 2017 Harald Hope

use strict;
use warnings;
use 5.008;

## defaults required to run:
my %dl = (
'curl' => 'true',
'fetch' => 'true',
'wget' => 'true',
'curl' => 'true',
);
# we only want to use HTTP::Tiny if it's present in user system.
# It is NOT part of core modules.
$dl{'tiny'} = 'true';
eval "use HTTP::Tiny"; # if not found, return has error messages etc
if ( $@ ) {
	$dl{'tiny'} = '';
}
sub check_program {
	return 1;
}

## Start actuala logic

sub download_file {
	my ($type, $url, $file) = @_;
	my ($cmd,$result,$args,$timeout);
	if ( ! $dl{'dl'} ){
		return 0;
	}
	if ($dl{'timeout'}){
		$timeout = "$dl{'timeout'}$dl_timeout";
	}
	# print "$dl{'dl'}\n";
	if ($dl{'dl'} eq 'tiny' ){
		$result = get_file($type, $url, $file);
	}
	elsif ($dl{'dl'}){
		if ($type eq 'stdout'){
			$args = $dl{'stdout'};
			$cmd = "$dl{'dl'} $no_ssl_opt $timeout $args $url $dl{'null'}";
			$result = qx($cmd);
		}
		else {
			$args = $dl{'file'};
			$cmd = "$dl{'dl'} $no_ssl_opt $timeout $args $file $url $dl{'null'}";
			system($cmd);
			$result = $?;
		}
	}
	return $result;
}

sub get_file {
	my ($type, $url, $file) = @_;
	my $response = HTTP::Tiny->new->get($url);
	my $return = 1;
	my $debug = 0;
	my $fh;
	
	if ( ! $response->{success} ){
		print "Failed to connect to server/file!\n";
		$return = 0;
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
			$return = $response->{content};
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

sub set_downloader {
	if ($dl{'tiny'}){
		$dl{'dl'} = 'tiny';
		$dl{'file'} = '';
		$dl{'null'} = '';
		$dl{'stdout'} = '';
		$dl{'timeout'} = '';
	}
	elsif ( $dl{'curl'} && check_program('curl')  ){
		$dl{'dl'} = 'curl';
		$no_ssl = ' --insecure';
		$dl{'file'} = '  -L -s -o ';
		$dl{'null'} = '';
		$dl{'stdout'} = ' -L -s ';
		$dl{'timeout'} = ' -y ';
	}
	elsif ($dl{'wget'} && check_program('wget') ){
		$dl{'dl'} = 'wget';
		$no_ssl = ' --no-check-certificate';
		$dl{'file'} = ' -q -O ';
		$dl{'null'} = '';
		$dl{'stdout'} = '  -q -O -';
		$dl{'timeout'} = ' -T ';
	}
	elsif ($dl{'fetch'} && check_program('fetch')){
		$dl{'dl'} = 'fetch';
		$no_ssl = ' --no-verify-peer';
		$dl{'file'} = ' -q -o ';
		$dl{'null'} = '';
		$dl{'stdout'} = ' -q -o -';
		$dl{'timeout'} = ' -T ';
	}
	elsif ( $bsd_type eq 'openbsd' && check_program('ftp') ){
		$dl{'dl'} = 'ftp';
		$dl{'file'} = ' -o ';
		$dl{'null'} = ' 2>/dev/null';
		$dl{'stdout'} = ' -q -O - ';
		$dl{'timeout'} = '';
	}
	else {
		$dl{'dl'} = '';
	}
}
