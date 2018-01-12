#!/usr/bin/env perl
## File: memory.pl
## Version: 1.1
## Date 2018-01-10
## License: GNU GPL v3 or greater
## Copyright (C) 2018 Harald Hope

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
my @paths = ('/sbin','/bin','/usr/sbin','/usr/bin','/usr/X11R6/bin','/usr/local/sbin','/usr/local/bin');

# arg: 1 - string to strip start/end space/\n from
# note: a few nano seconds are saved by using raw $_[0] for program
sub check_program {
	(grep { return "$_/$_[0]" if -e "$_/$_[0]"} @paths)[0];
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
	my @temp = split /$sep/, $string;
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

# openbsd/linux
# procs    memory       page                    disks    traps          cpu
# r b w    avm     fre  flt  re  pi  po  fr  sr wd0 wd1  int   sys   cs us sy id
# 0 0 0  55256 1484092  171   0   0   0   0   0   2   0   12   460   39  3  1 96
# freebsd:
# procs      memory      page                    disks     faults         cpu
# r b w     avm    fre   flt  re  pi  po    fr  sr ad0 ad1   in   sy   cs us sy id
# 0 0 0  21880M  6444M   924  32  11   0   822 827   0   0  853  832  463  8  3 88
# dragonfly
#  procs      memory      page                    disks     faults      cpu
#  r b w     avm    fre  flt  re  pi  po  fr  sr ad0 ad1   in   sy  cs us sy id
#  0 0 0       0  84060 30273993 2845 12742 1164 407498171 320960902   0   0 424453025 1645645889 1254348072 35 38 26

sub get_memory_data {
	eval $start if $b_log;
	my ($memory);
	if (my $file = system_files('meminfo') ) {
		$memory = get_memory_data_linux($file);
	}
	else {
		$memory = get_memory_data_bsd();
	}
	eval $end if $b_log;
	return $memory;
}

sub get_memory_data_linux {
	eval $start if $b_log;
	my ($file) = @_;
	my $memory = '';
	my $total = 0;
	my $not_used = 0;
	my @data = reader($file);
	foreach (@data){
		if ($_ =~ /^MemTotal:/){
			$total = get_piece($_,2);
		}
		elsif ($_ =~ /^(MemFree|Buffers|Cached):/){
			$not_used +=  get_piece($_,2);
		}
	}
	my $used = $total - $not_used;
	$memory = sprintf("%.1f/%.1f MB", $used/1024, $total/1024);
	log_data("memory: $memory") if $b_log;
	eval $end if $b_log;
	return $memory;
}
sub get_memory_data_bsd {
	eval $start if $b_log;
	my $memory = 'BSD-dev';
	my $total = 0;
	my $not_used = 0;
	
	eval $end if $b_log;
	return $memory;
}


### END MODULE CODE ##

### START TEST CODE ##

system_files('set');
print get_memory_data();



