#!/usr/bin/perl
## File: colors.pl
## Version: 1.1
## Date 2017-12-30
## License: GNU GPL v3 or greater
## Copyright (C) 2017 Harald Hope

use strict;
use warnings;
# use diagnostics;
use 5.008;

## stub code

my (%colors);
my $b_irc = 0;
my $start = '';
my $end = '';

use Data::Dumper qw(Dumper); # print_r

sub get_color_scheme {
	eval $start;
	my ($type) = @_;
	my @color_schemes = (
	[qw(EMPTY EMPTY EMPTY )],
	[qw(NORMAL NORMAL NORMAL )],
	# for dark OR light backgrounds
	[qw(BLUE NORMAL NORMAL)],
	[qw(BLUE RED NORMAL )],
	[qw(CYAN BLUE NORMAL )],
	[qw(DCYAN NORMAL NORMAL)],
	[qw(DCYAN BLUE NORMAL )],
	[qw(DGREEN NORMAL NORMAL )],
	[qw(DYELLOW NORMAL NORMAL )],
	[qw(GREEN DGREEN NORMAL )],
	[qw(GREEN NORMAL NORMAL )],
	[qw(MAGENTA NORMAL NORMAL)],
	[qw(RED NORMAL NORMAL)],
	# for light backgrounds
	[qw(BLACK DGREY NORMAL)],
	[qw(DBLUE DGREY NORMAL )],
	[qw(DBLUE DMAGENTA NORMAL)],
	[qw(DBLUE DRED NORMAL )],
	[qw(DBLUE BLACK NORMAL)],
	[qw(DGREEN DYELLOW NORMAL )],
	[qw(DYELLOW BLACK NORMAL)],
	[qw(DMAGENTA BLACK NORMAL)],
	[qw(DCYAN DBLUE NORMAL)],
	# for dark backgrounds
	[qw(WHITE GREY NORMAL)],
	[qw(GREY WHITE NORMAL)],
	[qw(CYAN GREY NORMAL )],
	[qw(GREEN WHITE NORMAL )],
	[qw(GREEN YELLOW NORMAL )],
	[qw(YELLOW WHITE NORMAL )],
	[qw(MAGENTA CYAN NORMAL )],
	[qw(MAGENTA YELLOW NORMAL)],
	[qw(RED CYAN NORMAL)],
	[qw(RED WHITE NORMAL )],
	[qw(BLUE WHITE NORMAL)],
	# miscellaneous
	[qw(RED BLUE NORMAL )],
	[qw(RED DBLUE NORMAL)],
	[qw(BLACK BLUE NORMAL)],
	[qw(BLACK DBLUE NORMAL)],
	[qw(NORMAL BLUE NORMAL)],
	[qw(BLUE MAGENTA NORMAL)],
	[qw(DBLUE MAGENTA NORMAL)],
	[qw(BLACK MAGENTA NORMAL)],
	[qw(MAGENTA BLUE NORMAL)],
	[qw(MAGENTA DBLUE NORMAL)],
	);
	if ($type eq 'count' ){
		return scalar @color_schemes;
	}
	if ($type eq 'full' ){
		return @color_schemes;
	}
	else {
		return @{$color_schemes[$type]};
		# print Dumper $color_schemes[$scheme_nu];
	}
	eval $end;
}
sub select_color_schemes {
	eval $start;
	
	eval $end;

}
sub set_color_scheme {
	eval $start;
	$colors{'scheme'} = shift;
	my $index = 0; # defaults to non irc
	
	# NOTE: qw(...) kills the escape, it is NOT the same as using 
	# Literal "..", ".." despite docs saying it is.
	my %color_palette = (
	'EMPTY' => [ '', '' ],
	'DGREY' => [ "\e[1;30m", "\x0314" ],
	'BLACK' => [ "\e[0;30m", "\x0301" ],
	'RED' => [ "\e[1;31m", "\x0304" ],
	'DRED' => [ "\e[0;31m", "\x0305" ],
	'GREEN' => [ "\e[1;32m", "\x0309" ],
	'DGREEN' => [ "\e[0;32m", "\x0303" ],
	'YELLOW' => [ "\e[1;33m", "\x0308" ],
	'DYELLOW' => [ "\e[0;33m", "\x0307" ],
	'BLUE' => [ "\e[1;34m", "\x0312" ],
	'DBLUE' => [ "\e[0;34m", "\x0302" ],
	'MAGENTA' => [ "\e[1;35m", "\x0313" ],
	'DMAGENTA' => [ "\e[0;35m", "\x0306" ],
	'CYAN' => [ "\e[1;36m", "\x0311" ],
	'DCYAN' => [ "\e[0;36m", "\x0310" ],
	'WHITE' => [ "\e[1;37m", "\x0300" ],
	'GREY' => [ "\e[0;37m", "\x0315" ],
	'NORMAL' => [ "\e[0m", "\x03" ],
	);
	if ( $b_irc){
		$index = 1;
	}
	my @scheme = get_color_scheme($colors{'scheme'});
	$colors{'c1'} = $color_palette{$scheme[0]}[$index];
	$colors{'c2'} = $color_palette{$scheme[1]}[$index];
	$colors{'cn'} = $color_palette{$scheme[2]}[$index];
	print Dumper \@scheme;
	print "$colors{'c1'}here$colors{'c2'} we are!$colors{'cn'}\n";
	eval $end;
}

sub set_colors {
	eval $start;
	# it's already been set with -c 0-43
	if ( exists $colors{'c1'} ){
		return 1;
	}
	# This let's user pick their color scheme. For IRC, only shows the color schemes, 
	# no interactive. The override value only will be placed in user config files. 
	# /etc/inxi.conf can also override
	if (exists $colors{'selector'}){
		select_color_schemes();
		return 2;
	}
	# set the default, then override as required
	my $color_scheme = $colors{'default'};
	# these are set in user configs
	if (defined $colors{'global'}){
		$color_scheme = $colors{'global'};
	}
	else {
		if ( $b_irc ){
			if (defined $colors{'irc-x-term'} && $b_display && $client{'console-irc'}){
				$color_scheme = $colors{'irc-x-term'};
			}
			elsif (defined $colors{'console-irc'} && !$b_display){
				$color_scheme = $colors{'console-irc'};
			}
			elsif ( defined $colors{'irc'}) {
				$color_scheme = $colors{'irc'};
			}
		}
		else {
			if (defined $colors{'console'} && !$b_display){
				$color_scheme = $colors{'console'};
			}
			elsif (defined $colors{'virt-term'}){
				$color_scheme = $colors{'console'};
			}
		}
	}
	set_color_scheme($color_scheme);
	eval $end;
}

print get_color_scheme('count'), "\n";
set_color_scheme(30);

# print $temp[0] . " " . $temp[2],"\n";
# 
# print ref $color_schemes[18], "\n";



# print "${$color_schemes[18]}[1]\n";
# 
# print Dumper \$temp;

# print "$temp[1]\n";
# 
# print "$co{$temp[0]} hello world $co{$temp[2]}\n";
