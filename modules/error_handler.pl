#!/usr/bin/env perl
## File: error_handler.pl
## Version: 1.0
## Date 2017-12-11
## License: GNU GPL v3 or greater
## Copyright (C) 2017 Harald Hope

## INXI INFO ##
my $self_name='pinxi';
my $self_version='2.9.00';
my $self_date='2017-12-11';
my $self_patch='022-p';

use strict;
use warnings;
# use diagnostics;
use 5.008;


sub error_handler {
	my ( $num, $one, $two) = @_;
	print "Error $num: option: $one";
	if ($two){
		print " value: $two is incorrect.";
	}
	print "\nCheck -h for correct parameters.\n";
	exit $num;
}
