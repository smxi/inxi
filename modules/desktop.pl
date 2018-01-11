#!/usr/bin/env perl
## File: desktop.pl
## Version: 1.0
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

### START CODE REQUIRED BY THIS MODULE ##

### END CODE REQUIRED BY THIS MODULE ##

### START MODULE CODE ##

### END MODULE CODE ##

### START TEST CODE ##



