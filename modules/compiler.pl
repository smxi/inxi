#!/usr/bin/env perl
## File: compiler.pl
## Version: 1.2
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
my $self_date='2017-12-31';
my $self_patch='037-p';

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

# arg: 1 - string to strip start/end space/\n from
# note: a few nano seconds are saved by using raw $_[0] for program
sub check_program {
	(grep { return "$_/$_[0]" if -e "$_/$_[0]"} @paths)[0];
}

sub error_handler {
	my ($err, $message, $alt1) = @_;
	print "$err: $message err: $alt1\n";
	exit;
}

sub log_data {}

# arg: 1 - full file path, returns array of file lines.
# note: chomp has to chomp the entire action, not just <$fh>
sub reader {
	eval $start if $b_log;
	my ($file) = @_;
	open( my $fh, '<', $file ) or error_handler('open', $file, $!);
	chomp(my @rows = <$fh>);
	eval $end if $b_log;
	return @rows;
}

### END DEFAULT CODE ##

### START CODE REQUIRED BY THIS MODULE ##

# args: 1: set|hash key to return either null or path
sub system_files {
	my ($file) = @_;
	if ( $file eq 'set'){
		%files = (
		'asound-cards' => '/proc/asound/cards',
		'asound-modules' => '/proc/asound/modules',
		'asound-version' => '/proc/asound/version',
		'cpuinfo' => '/proc/cpuinfo',
		'dmesg-boot' => '/var/run/dmesg.boot',
		'lsb-release' => '/etc/lsb-release',
		'mdstat' => '/proc/mdstat',
		'meminfo' => '/proc/meminfo',
		'modules' => '/proc/modules',
		'mounts' => '/proc/mounts',
		'os-release' => '/etc/os-release',
		'partitions' => '/proc/partitions',
		'scsi' => '/proc/scsi/scsi',
		'version' => '/proc/version',
		'xorg-log' => '/var/log/Xorg.0.log'
		);
		foreach ( keys %files ){
			$system_files{$_} = -e $files{$_} ? $files{$_} : '';
		}
		if ( ! $system_files{'xorg-log'} && check_program('xset') ){
			my $data = qx(xset q 2>/dev/null);
			foreach ( split /\n/, $data){
				if ($_ =~ /Log file/i){
					$system_files{'xorg-log'} = get_piece($_,3);
					last;
				}
			}
		}
	}
	else {
		return $system_files{$file};
	}
}

### END CODE REQUIRED BY THIS MODULE ##

### START MODULE CODE ##

sub get_compiler_version {
	eval $start if $b_log;
	my (@compiler);
	if (my $file = system_files('version') ) {
		@compiler = get_compiler_version_linux($file);
	}
	else {
		@compiler = get_compiler_version_bsd();
	}
	eval $end if $b_log;
	return @compiler;
}
sub get_compiler_version_bsd {
	eval $start if $b_log;
	my (@compiler);
	
	
	eval $end if $b_log;
	return @compiler;
}
sub get_compiler_version_linux {
	eval $start if $b_log;
	my ($file) = @_;
	my (@compiler,$type);
	my @data = reader($file);
	my $result = $data[0] if @data;
	if ($result){
		$result =~ /(gcc|clang).*version\s([\S]+)/;
		# $result = $result =~ /\*(gcc|clang)\*eval\*/;
		if ($1){
			$type = $2;
			$type ||= 'N/A'; # we don't really know what linux clang looks like!
			@compiler = ($1,$type);
		}
	}
	log_data(@compiler) if $b_log;
	
	eval $end if $b_log;
	return @compiler;
}

### END MODULE CODE ##

### START TEST CODE ##

system_files('set');

print join ' - ', get_compiler_version(),"\n";

