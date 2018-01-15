#!/usr/bin/env perl
## File: processes.pl
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

my @ps_aux = grabber('ps aux');

my $ps_count;
my %show = (
'ps-cpu' => 1,
'ps-mem' => 1,
);

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

### END CODE REQUIRED BY THIS MODULE ##

### START MODULE CODE ##

## Get ProcessData 
{
package ProcessData;

sub get {
	eval $start if $b_log;
	my (@processes,@rows);
	if ($show{'ps-cpu'}){
		@rows = cpu_processes();
		@processes = (@processes,@rows);
	}
	if ($show{'ps-mem'}){
		@rows = mem_processes();
		@processes = (@processes,@rows);
	}
	return @processes;
	eval $end if $b_log;
}
sub cpu_processes {
	eval $start if $b_log;
	my ($j,$num,$cpu,$cpu_mem,$mem) = (0,0,'','','');
	my (@processes);
	my $count = ($b_irc)? 5: $ps_count;
	my @rows = sort { 
		my @a = split(/\s+/,$a); 
		my @b = split(/\s+/,$b); 
		$b[2] <=> $a[2] } @ps_aux;
	@rows = splice @rows,0,$count;
	$cpu_mem = ' - Memory: MB / % used' if $extra > 0;
	$j = scalar @rows;
	my $throttled = throttled($ps_count,$count,$j);
	my @data = (
	{$num++ . "#CPU  % used - Command - pid$cpu_mem - top" => "$count$throttled",},
	);
	@processes = (@processes,@data);
	my $i = 1;
	foreach (@rows){
		$num = 1;
		$j = scalar @processes;
		my @row = split /\s+/, $_;
		my @command = process_starter(scalar @row, $row[10],$row[11]);
		@data = (
		{
		$num++ . "#" . $i++ => '',
		$num++ . "#cpu" => $row[2] . '%',
		$num++ . "#command" => $command[0],
		},
		);
		@processes = (@processes,@data);
		if ($command[1]) {
			$processes[$j]{$num++ . "#started by"} = $command[1];
		}
		$processes[$j]{$num++ . "#pid"} = $row[1];
		if ($extra > 0){
			my $decimals = ($row[5]/1024 > 10 ) ? 1 : 2;
			$mem = (defined $row[5]) ? sprintf( "%.${decimals}f", $row[5]/1024 ) . 'MB' : 'N/A';
			$mem .= ' (' . $row[3] . '%)';
			$processes[$j]{$num++ . "#mem"} = $mem;
		}
		#print Data::Dumper::Dumper \@processes, "i: $i; j: $j ";
	}
	eval $end if $b_log;
	return @processes;
}
sub mem_processes {
	eval $start if $b_log;
	my ($j,$num,$cpu,$cpu_mem,$mem) = (0,0,'','','');
	my (@data,@processes,$memory);
	my $count = ($b_irc)? 5: $ps_count;
	my @rows = sort { 
		my @a = split(/\s+/,$a); 
		my @b = split(/\s+/,$b); 
		$b[5] <=> $a[5] } @ps_aux;
	@rows = splice @rows,0,$count;
	if (!$show{'info'}){
		$memory = main::get_memory_data();
		$memory ||= 'N/A';
		@data = (
		{$num++ . "#System Memory" => '',
		$num++ . "#Used/Total" => $memory,},
		);
		@processes = (@processes,@data);
	}
	$cpu_mem = ' - CPU: % used' if $extra > 0;
	$j = scalar @rows;
	my $throttled = throttled($ps_count,$count,$j);
	@data = (
	{$num++ . "#Memory MB/% used - Command - pid$cpu_mem - top" => "$count$throttled",},
	);
	@processes = (@processes,@data);
	my $i = 1;
	foreach (@rows){
		$num = 1;
		$j = scalar @processes;
		my @row = split /\s+/, $_;
		my $decimals = ($row[5]/1024 > 10 ) ? 1 : 2;
		$mem = ($row[5]) ? sprintf( "%.${decimals}f", $row[5]/1024 ) . ' MB' : 'N/A';
		my @command = process_starter(scalar @row, $row[10],$row[11]);
		if ($extra > 0){
			$mem .= " (" . $row[2] . "%)"; 
		}
		@data = (
		{
		$num++ . "#" . $i++ => '',
		$num++ . "#mem" => $mem,
		$num++ . "#command" => $command[0],
		},
		);
		@processes = (@processes,@data);
		if ($command[1]) {
			$processes[$j]{$num++ . "#started by"} = $command[1];
		}
		$processes[$j]{$num++ . "#pid"} = $row[1];
		if ($extra > 0){
			$cpu = $row[3] . '%';
			$processes[$j]{$num++ . "#cpu"} = $cpu;
		}
		#print Data::Dumper::Dumper \@processes, "i: $i; j: $j ";
	}
	eval $end if $b_log;
	return @processes;
}
sub process_starter {
	my ($count, $row10, $row11) = @_;
	my (@return);
	# note: [migration/0] would clear with a simple basename
	if ($count > 11 && $row11 =~ /^\//){
		$row11 =~ s/^\/.*\///;
		$return[0] = $row11;
		$row10 =~ s/^\/.*\///;
		$return[1] = $row10;
	}
	else {
		$row10 =~ s/^\/.*\///;
		$return[0] = $row10;
		$return[1] = '';
	}
	return @return;
}
sub throttled {
	my ($ps_count,$count,$j) = @_;
	my $throttled = '';
	if ($count > $j){
		$throttled = " (only $j processes)";
	}
	elsif ($count < $ps_count){
		$throttled = " (throttled from $ps_count)";
	}
	return $throttled;
}
}

### END MODULE CODE ##

### START TEST CODE ##



