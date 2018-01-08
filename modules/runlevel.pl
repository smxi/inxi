#!/usr/bin/env perl
## File: runlevel.pl
## Version: 1.0
## Date 2018-01-07
## License: GNU GPL v3 or greater
## Copyright (C) 2018 Harald Hope

use strict;
use warnings;
use 5.008;
use Net::FTP;

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

## returns result of test, 0/1, false/true
## arg: program to find in PATH
sub check_program {
	grep { -x "$_/$_[0]"}split /:/,$ENV{PATH};
}

# arg: 1 - command to turn into an array; 2 - optional: splitter
# similar to reader() except this creates an array of data 
# by lines from the command arg
sub data_grabber {
	eval $start if $b_log;
	my ($cmd,$split) = @_;
	$split ||= "\n";
	my @result = split /$split/, qx($cmd);
	eval $end if $b_log;
	return @result;
}

sub error_handler {
	my ($err, $message, $alt1) = @_;
	print "$err: $message err: $alt1\n";
}

# args: 0 - the string to get piece of
# 2 - the position in string, starting at 1 for 0 index.
# 3 - the separator, default is ' '
sub get_piece {
	eval $start if $b_log;
	my ($string, $num, $sep) = @_;
	$num--;
	$sep ||= '\s+';
	$string =~ s/^\s+|\s+$//;
	my @temp = split /$sep/, $string, -1;
	eval $end if $b_log;
	if ( exists $temp[$num] ){
		return $temp[$num];
	}
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
### START CODE REQUIRED BY THIS MODULE ##

### END CODE REQUIRED BY THIS MODULE ##

### START MODULE CODE ##

# # check? /var/run/nologin for bsds?
sub get_runlevel_data {
	eval $start if $b_log;
	my (@runlevels,@data);
	my ($runlevel,@default) = ('','');;
	if (check_program('runlevel')){
		$runlevel = (data_grabber('runlevel'))[0];
		$runlevel =~ s/[^\d]//g;
	}
	if ($extra > 1){
		@default = get_runlevel_data_default();
	}
	if ($runlevel){
		@runlevels = ($runlevel,@default);
	}
	eval $end if $b_log;
	return @runlevels;
}
sub get_runlevel_data_default {
	eval $start if $b_log;
	my $default = '';
	my $b_systemd = 0;
	my $inittab = '/etc/inittab';
	my $systemd = '/etc/systemd/system/default.target';
	my $upstart = '/etc/init/rc-sysinit.conf';
	if (-e $systemd){
		$default = readlink($systemd);
		$default =~ s/.*\/// if $default; 
		$b_systemd = 1;
	}
	elsif (-e $upstart){
		$default = (grep { /^env[[:space:]]+DEFAULT_RUNLEVEL/ } reader($upstart))[0];
		$default = (split /=/, $default)[1];
	}
	if (!$default && -e $inittab ){
		$default = (grep { /^id.*initdefault/ } reader($inittab))[0];
		$default = (split /:/, $default)[1];
	}
	eval $end if $b_log;
	return ($default,$b_systemd);
}

### END MODULE CODE ##

### START TEST CODE ##

print join( ', ', get_runlevel_data()), "\n";

