#!/usr/bin/env perl

# File: sys_tree_traverse.pl
# Version: 1.1
# Date 2017-10-31

use strict;
use warnings;
use 5.008;
use File::Find;

my @content = (); 
find( \&wanted, "/sys");
process_data( @content );
sub wanted {
	return if -d; # not directory
	return unless -e; # Must exist
	return unless -r; # Must be readable
	return unless -f; # Must be file
	# note: a new file in 4.11 /sys can hang this, it is /parameter/ then
	# a few variables. Since inxi does not need to see that file, we will
	# not use it. Also do not need . files or __ starting files
	return if $File::Find::name =~ /\/(\.[a-z]|__|parameters\/|debug\/)/;
	# comment this one out if you experience hangs or if 
	# we discover syntax of foreign language characters
	return unless -T; # Must be ascii like
	# print $File::Find::name . "\n";
	push @content, $File::Find::name;
	return;
}
sub process_data {
	my $result = "";
	my $row = "";
	my $fh;
	my $data="";
	my $sep="";
	# no sorts, we want the order it comes in
	# @content = sort @content; 
	foreach (@content){
		$data="";
		$sep="";
		open($fh, "<$_");
		while ($row = <$fh>) {
			chomp $row;
			$data .= $sep . "\"" . $row . "\"";
			$sep=", ";
		}
		$result .= "$_:[$data]\n";
		# print "$_:[$data]\n"
	}
	# print scalar @content . "\n";
	print "$result";
}
