#!/usr/bin/env perl
## File: memory.pl
## Version: 1.3
## Date 2018-01-14
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

# Duplicates the functionality of awk to allow for one liner
# type data parsing. note: -1 corresponds to awk NF
# args 1: array of data; 2: search term; 3: field result; 4: separator
# correpsonds to: awk -F='separator' '/search/ {print $2}' <<< @data
# array is sent by reference so it must be dereferenced
# NOTE: if you just want the first row, pass it \S as search string
# NOTE: if $num is undefined, it will skip the second step
sub awk {
	eval $start if $b_log;
	my ($ref,$search,$num,$sep) = @_;
	my ($result);
	return if ! @$ref || ! $search;
	foreach (@$ref){
		if (/$search/i){
			$result = $_;
			$result =~ s/^\s+|\s+$//g;
			last;
		}
	}
	if ($result && defined $num){
		$sep ||= '\s+';
		$num-- if $num > 0; # retain the negative values as is
		$result = (split /$sep/, $result)[$num];
		$result =~ s/^\s+|\s+$//g if $result;
	}
	eval $end if $b_log;
	return $result;
}

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

# arg: 1 - command to turn into an array; 2 - optional: splitter
# 3 - optionsl, strip and clean data
# similar to reader() except this creates an array of data 
# by lines from the command arg
sub grabber {
	eval $start if $b_log;
	my ($cmd,$split,$strip) = @_;
	$split ||= "\n";
	my @rows = split /$split/, qx($cmd);
	if ($strip && @rows){
		@rows = grep {/^\s*[^#]/} @rows;
		@rows = map {s/^\s+|\s+$//g; $_} @rows if @rows;
	}
	eval $end if $b_log;
	return @rows;
}
sub log_data {}

# arg: 1 - full file path, returns array of file lines.
# 2 - optionsl, strip and clean data
# note: chomp has to chomp the entire action, not just <$fh>
sub reader {
	eval $start if $b_log;
	my ($file,$strip) = @_;
	open( my $fh, '<', $file ) or error_handler('open', $file, $!);
	chomp(my @rows = <$fh>);
	if ($strip && @rows){
		@rows = grep {/^\s*[^#]/} @rows;
		@rows = map {s/^\s+|\s+$//g; $_} @rows if @rows;
	}
	eval $end if $b_log;
	return @rows;
}

# args: 1 - the file to create if not exists
sub toucher {
	my ($file ) = @_;
	if ( ! -e $file ){
		open( my $fh, '>', $file ) or error_handler('create', $file, $!);
	}
}
# calling it trimmer to avoid conflicts with existing trim stuff
# arg: 1 - string to be right left trimmed. Also slices off \n so no chomp needed
# this thing is super fast, no need to log its times etc, 0.0001 seconds or less
sub trimmer {
	#eval $start if $b_log;
	my ($str) = @_;
	$str =~ s/^\s+|\s+$|\n$//g; 
	#eval $end if $b_log;
	return $str;
}

sub uniq {
	my %seen;
	grep !$seen{$_}++, @_;
}

# arg: 1 file full  path to write to; 2 - arrayof data to write. 
# note: turning off strict refs so we can pass it a scalar or an array reference.
sub writer {
	my ($path, $ref_content) = @_;
	my ($content);
	no strict 'refs';
	# print Dumper $ref_content, "\n";
	if (ref $ref_content eq 'ARRAY'){
		$content = join "\n", @$ref_content or die "failed with error $!";
	}
	else {
		$content = scalar $ref_content;
	}
	open(my $fh, '>', $path) or error_handler('open',"$path", "$!");
	print $fh $content;
	close $fh;
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
	my $percent = ($used && $total) ? sprintf(" (%.1f%%)", ($used/$total)*100) : '';
	$memory = sprintf("%.1f/%.1f MB", $used/1024, $total/1024) . $percent;
	log_data("memory: $memory") if $b_log;
	eval $end if $b_log;
	return $memory;
}
# openbsd/linux
# procs    memory       page                    disks    traps          cpu
# r b w    avm     fre  flt  re  pi  po  fr  sr wd0 wd1  int   sys   cs us sy id
# 0 0 0  55256 1484092  171   0   0   0   0   0   2   0   12   460   39  3  1 96
# freebsd:
# procs      memory      page                    disks     faults         cpu
# r b w     avm    fre   flt  re  pi  po    fr  sr ad0 ad1   in   sy   cs us sy id
# 0 0 0  21880M  6444M   924  32  11   0   822 827   0   0  853  832  463  8  3 88
# with -H
# 2 0 0 14925812  936448    36  13  10   0    84  35   0   0   84   30   42 11  3 86
# dragonfly
#  procs      memory      page                    disks     faults      cpu
#  r b w     avm    fre  flt  re  pi  po  fr  sr ad0 ad1   in   sy  cs us sy id
#  0 0 0       0  84060 30273993 2845 12742 1164 407498171 320960902   0   0 ....
sub get_memory_data_bsd {
	eval $start if $b_log;
	my $memory = 'BSD-dev';
	my $total = 0;
	my $avg = 0;
	my (@data,$b_free);
	
	if (my $program = check_program('vmstat')){
		# see above, it's the last line
		my $row = (grabber('vmstat -H 2>/dev/null','\n','strip'))[-1];
		if ( $row ){
			@data = split /\s+/, $row;
			# dragonfly can have 0 avg, but they may fix that so make test dynamic
			if ($data[3] != 0){
				$avg = sprintf ('%.1f',$data[3]/1024);
			}
			elsif ($data[4] != 0){
				$b_free = 1;
				$avg = sprintf ('%.1f',$data[4]/1024);
			}
		}
	}
	## code to get total goes here:
	my $type = ($b_free) ? ' free':'' ;
	if ($avg && !$total){
		$memory = "$avg$type/(total N/A) MB";
	}
	elsif ($avg && $total) {
		my $used = (!$b_free) ? $avg : $total - $avg;
		my $percent = ($used && $total) ? sprintf(" (%.1f%%)", ($used/$total)*100) : '';
		$memory = "$used$type/$total MB" . $percent;
	}
	eval $end if $b_log;
	return $memory;
}


### END MODULE CODE ##

### START TEST CODE ##

system_files('set');
print get_memory_data();



