#!/usr/bin/env perl
## File: file_downloader.pl
## Version: 1.5
## Date 2018-01-10
## License: GNU GPL v3 or greater
## Copyright (C) 2017-18 Harald Hope

use strict;
use warnings;
use 5.008;
use Data::Dumper qw(Dumper); # print_r

### START DEFAULT CODE ##
my $self_name='pinxi';
my $self_version='2.9.00';
my $self_date='2018-01-07';
my $self_patch='086-p';

my (@app);
my (%files,%system_files);
my $start = '';
my $end = '';
my $b_irc = 1;
my $bsd_type = '';
my $b_display = 1;
my $b_root = 0;
my $b_log;
my $extra = 2;
my @paths = qw(/sbin /bin /usr/sbin /usr/bin /usr/X11R6/bin /usr/local/sbin /usr/local/bin);


# arg: 1 - string to strip start/end space/\n from
# note: a few nano seconds are saved by using raw $_[0] for program
sub check_program {
	(grep { return "$_/$_[0]" if -e "$_/$_[0]"} @paths)[0];
}

### END DEFAULT CODE ##

### START CODE REQUIRED BY THIS MODULE ##
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
my $dl_timeout = 4;

### START MODULE CODE ##

sub download_file {
	my ($type, $url, $file) = @_;
	my ($cmd,$args,$timeout);
	my $result = 1;
	$dl{'no-ssl-opt'} ||= '';
	$dl{'spider'} ||= '';
	if ( ! $dl{'dl'} ){
		return 0;
	}
	if ($dl{'timeout'}){
		$timeout = "$dl{'timeout'}$dl_timeout";
	}
	# print "$dl{'no-ssl-opt'}\n";
	 print "$dl{'dl'}\n";
	# tiny supports spider sort of
	if ($dl{'dl'} eq 'tiny' ){
		$result = get_file($type, $url, $file);
	}
	else {
		if ($type eq 'stdout'){
			$args = $dl{'stdout'};
			$cmd = "$dl{'dl'} $dl{'no-ssl-opt'} $timeout $args $url $dl{'null'}";
			$result = qx($cmd);
		}
		elsif ($type eq 'file') {
			$args = $dl{'file'};
			$cmd = "$dl{'dl'} $dl{'no-ssl-opt'} $timeout $args $file $url $dl{'null'}";
			system($cmd);
			$result = $?;
		}
		elsif ( $dl{'dl'} eq 'wget' && $type eq 'spider'){
			$cmd = "$dl{'dl'} $dl{'no-ssl-opt'} $timeout $dl{'spider'} $url";
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
	$dl{'no-ssl'} = '';
	$dl{'null'} = '';
	$dl{'spider'} = '';
	if ($dl{'tiny'}){
		$dl{'dl'} = 'tiny';
		$dl{'file'} = '';
		$dl{'stdout'} = '';
		$dl{'timeout'} = '';
	}
	elsif ( $dl{'curl'} && check_program('curl')  ){
		$dl{'dl'} = 'curl';
		$dl{'file'} = '  -L -s -o ';
		$dl{'no-ssl'} = ' --insecure';
		$dl{'stdout'} = ' -L -s ';
		$dl{'timeout'} = ' -y ';
	}
	elsif ($dl{'wget'} && check_program('wget') ){
		$dl{'dl'} = 'wget';
		$dl{'file'} = ' -q -O ';
		$dl{'no-ssl'} = ' --no-check-certificate';
		$dl{'spider'} = ' -q --spider';
		$dl{'stdout'} = '  -q -O -';
		$dl{'timeout'} = ' -T ';
	}
	elsif ($dl{'fetch'} && check_program('fetch')){
		$dl{'dl'} = 'fetch';
		$dl{'file'} = ' -q -o ';
		$dl{'no-ssl'} = ' --no-verify-peer';
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

sub set_perl_downloader {
	my ($downloader) = @_;
	$downloader =~ s/perl/tiny/;
	return $downloader;
}

### END MODULE CODE ##

### START TEST CODE ##
