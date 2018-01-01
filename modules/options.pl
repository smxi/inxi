#!/usr/bin/env perl
## File: options.pl
## Version: 1.3
## Date 2017-12-31
## License: GNU GPL v3 or greater
## Copyright (C) 2017 Harald Hope

use strict;
use warnings;
# use diagnostics;
use 5.008;

use Getopt::Long qw(GetOptions);
# Note: default auto_abbrev is enabled, that's fine
Getopt::Long::Configure ('bundling', 'no_ignore_case', 
'no_getopt_compat', 'no_auto_abbrev','pass_through');

## NOTE: Includes dummy sub and variables to allow for running for debugging.

sub error_handler {
	my ($err, $one, $two) = @_;
	print "Err: $err Value: $one Value2: $two\n";
}
sub get_color_scheme {
	return 32;
}
sub get_defaults {}
sub set_color_scheme {}
sub set_display_width {}
sub set_downloader {}
sub set_perl_downloader {}
sub update_me {}
my (%colors,%show,%dl,$debug,%test,$b_weather,$ps_count,$b_update,
$display,$output_type,$b_irc,$ftp_alt);
my $start = '';
my $end = '';

## start actual code

sub get_options{
	my (@args) = @_;
	# my @argv = @ARGV;
	$show{'short'} = 1;
	# $show{''} = 1;
	#$opt_parser->configure('no_ignore_case');
	# GetOptionsFromArray(\@argv, 
	GetOptions (
	'A|audio' => sub {
		$show{'short'} = 0;
		$show{'audio'} = 1;},
	'b|basic' => sub {
		$show{'short'} = 0;
		$show{'battery'} = 1;
		$show{'cpu-basic'} = 1;
		$show{'raid-basic'} = 1;
		$show{'disk-total'} = 1;
		$show{'graphics'} = 1;
		$show{'info'} = 1;
		$show{'machine'} = 1;
		$show{'network'} = 1;},
	'B|battery' => sub {
		$show{'short'} = 0;
		$show{'battery'} = 1;
		$show{'battery-forced'} = 1; },
	'c|color:i' => sub {
		my ($opt,$arg) = @_;
		$output_type = 'print-basic';
		if ( $arg >= 0 && $arg <= get_color_scheme('count') ){
			set_color_scheme($arg);
		}
		elsif ( $arg >= 94 && $arg <= 99 ){
			$colors{'selector'} = $arg;
		}
		else {
			error_handler('bad-arg', $opt, $arg);
		} },
	'C|cpu' => sub {
		$show{'short'} = 0;
		$show{'cpu'} = 1; },
	'd|disk-all' => sub {
		$show{'short'} = 0;
		$show{'disk'} = 1;
		$show{'optical-full'} = 1; },
	'D' => sub {
		$show{'short'} = 0;
		$show{'disk'} = 1; },
	'f|cpu-flags' => sub {
		$show{'short'} = 0;
		$show{'cpu'} = 1;
		$show{'cpu-flags'} = 1; },
	'F|full' => sub {
		$show{'short'} = 0;
		$show{'audio'} = 1;
		$show{'battery'} = 1;
		$show{'cpu'} = 1;
		$show{'disk'} = 1;
		$show{'graphics'} = 1;
		$show{'info'} = 1;
		$show{'machine'} = 1;
		$show{'network'} = 1;
		$show{'network-advanced'} = 1;
		$show{'partitions'} = 1;
		$show{'raid'} = 1;
		$show{'sensors'} = 1;
		$show{'system'} = 1; },
	'G|graphics' => sub {
		$show{'short'} = 0;
		$show{'graphics'} = 1; },
	'i|ip' => sub {
		$show{'short'} = 0;
		$show{'ip'} = 1;
		$show{'network'} = 1;
		$show{'network-advanced'} = 1; },
	'I|info' => sub {
		$show{'short'} = 0;
		$show{'info'} = 1; },
	'l|label' => sub {
		$show{'short'} = 0;
		$show{'labels'} = 1;
		$show{'partitions'} = 1; },
	'm|memory' => sub {
		$show{'short'} = 0;
		$show{'memory'} = 1; },
	'M|machine' => sub {
		$show{'short'} = 0;
		$show{'machine'} = 1; },
	'n|network-advanced' => sub {
		$show{'short'} = 0;
		$show{'network'} = 1;
		$show{'network-advanced'} = 1; },
	'N|network' => sub {
		$show{'short'} = 0;
		$show{'network'} = 1; },
	'o|unmounted' => sub {
		$show{'short'} = 0;
		$show{'unmounted'} = 1; },
	'p|partitions-full' => sub {
		$show{'short'} = 0;
		$show{'partitions'} = 1;
		$show{'partitions-full'} = 1; },
	'P|partitions' => sub {
		$show{'short'} = 0;
		$show{'partitions'} = 1; },
	'r|repos' => sub {
		$show{'short'} = 0;
		$show{'repos'} = 1; },
	'R|raid' => sub {
		$show{'short'} = 0;
		$show{'raid'} = 1;
		$show{'raid-forced'} = 1; },
	's|sensors' => sub {
		$show{'short'} = 0;
		$show{'sensors'} = 1; },
	'S|system' => sub {
		$show{'short'} = 0;
		$show{'system'} = 1; },
	't|processes:s' => sub {
		my ($opt,$arg) = @_;
		$show{'short'} = 0;
		if ( $arg =~ /^([cm]+)([1-9]|1[0-9]|20)?$/ ){
			if ($arg =~ /c/){
				$show{'ps-cpu'} = 1;
			}
			if ($arg =~ /m/){
				$show{'ps-mem'} = 1;
			}
			if ($arg =~ /([0-9]+)/ ){
				$ps_count = $1;
			}
		}
		else {
			error_handler('bad-arg',$opt,$arg);
		} },
	'u|uuid' => sub {
		$show{'short'} = 0;
		$show{'partitions'} = 1;
		$show{'uuids'} = 1; },
	'U|update:s' => sub { # 1,2,3 OR http://myserver/path/inxi
		my ($opt,$arg) = @_;
		$show{'short'} = 0;
		my ($self_download,$download_id);
		if ( $b_update ){
			if ( $arg =~ /^\d$/){
				$download_id = "branch $arg";
				$self_download = get_defaults("inxi-branch-$arg");
			}
			elsif ( $arg =~ /^http/){
				$download_id = 'alt server';
				$self_download = $arg;
			}
			else {
				$download_id = 'pinxi server';
				$self_download = get_defaults('inxi-pinxi');
			}
# 			else {
# 				$download_id = 'source server';
# 				$self_download = get_defaults('inxi-main');
# 			}
			if ($self_download){
				update_me( $self_download, $download_id );
			}
			else {
				error_handler('bad-arg', $opt, $arg);
			}
		}
		else {
			error_handler('distro-block', $opt);
		} },
	'v|verbosity:i' => sub {
		my ($opt,$arg) = @_;
		$show{'short'} = 0;
		if ( $arg =~ /^[0-7]$/ ){
			if ($arg == 0 ){
				$show{'short'} = 1;
			}
			if ($arg >= 1 ){
				$show{'cpu-basic'} = 1;
				$show{'disk-total'} = 1;
				$show{'graphics'} = 1;
				$show{'info'} = 1;
				$show{'system'} = 1;
			}
			if ($arg >= 2 ){
				$show{'battery'} = 1;
				$show{'disk-basic'} = 1;
				$show{'raid-basic'} = 1;
				$show{'machine'} = 1;
				$show{'network'} = 1;
			}
			if ($arg >= 3 ){
				$show{'network-advanced'} = 1;
				$show{'cpu'} = 1;
				$show{'extra'} = 1;
			}
			if ($arg >= 4 ){
				$show{'disk'} = 1;
				$show{'partitions'} = 1;
			}
			if ($arg >= 5 ){
				$show{'audio'} = 1;
				$show{'memory'} = 1;
				$show{'labels'} = 1;
				$show{'memory'} = 1;
				$show{'raid'} = 1;
				$show{'sensors'} = 1;
				$show{'uuid'} = 1;
			}
			if ($arg >= 6 ){
				$show{'optical-full'} = 1;
				$show{'partitions-full'} = 1;
				$show{'unmounted'} = 1;
				$show{'extra'} = 2;
			}
			if ($arg >= 7 ){
				$show{'ip'} = 1;
				$show{'raid-forced'} = 1;
				$show{'extra'} = 3;
			}
		}
		else {
			error_handler('bad-arg',$opt,$arg);
		} },
	'V|version' => sub { 
		$output_type = 'print-basic';
		show_version(); },
	'w|weather' => sub {
		my ($opt) = @_;
		$show{'short'} = 0;
		if ( $b_weather ){
			$show{'weather'} = 1;
		}
		else {
			error_handler('distro-block', $opt);
		} },
	'W|weather-location:s' => sub {
		my ($opt,$arg) = @_;
		$arg ||= '';
		$show{'short'} = 0;
		if ( $b_weather ){
			if ( $arg){
				$show{'weather'} = 1;
				$show{'weather-location'} = 1;
			}
			else {
				error_handler('bad-arg',$opt,$arg);
			}
		}
		else {
			error_handler('distro-block', $opt);
		} },
	'x|extra:i' => sub {
		my ($opt,$arg) = @_;
		if ($arg > 0){
			$show{'extra'} = $arg;
		}
		else {
			$show{'extra'}++;
		} },
	'y|width:i' => sub {
		my ($opt, $arg) = @_;
		if ( $arg =~ /\d/ && $arg >= 80 ){
			set_display_width($arg);
		}
		else {
			error_handler('bad-arg', $opt, $arg);
		} },
	'z|filter' => sub {
		$show{'filter'} = 1; },
	'Z|filter-override' => sub {
		$show{'filter-override'} = 1; },
	'h|help|?' => sub {
		$output_type = 'print-basic';
		show_options('standard'); },
	'H|help-full' => sub {
		$output_type = 'print-basic';
		show_options('full'); },
	'alt:i' => sub { 
		my ($opt,$arg) = @_;
		my %alts = (
		'0' => sub {$test{'1'} = 1;},
		'1' => sub {$test{'1'} = 1;},
		'2' => sub {$test{'2'} = 1;},
		'3' => sub {$test{'3'} = 1;},
		'30' => sub {$b_irc = 0;},
		'31' => sub {$show{'host'} = 0;},
		'32' => sub {$show{'host'} = 1;},
		'34' => sub {$dl{'no-ssl-opt'}=$dl{'no-ssl'};},
		'40' => sub {
			$dl{'tiny'} = 0;
			set_downloader();},
		'41' => sub {
			$dl{'curl'} = 0;
			set_downloader();},
		'42' => sub {
			$dl{'fetch'} = 0;
			set_downloader();},
		'43' => sub {
			$dl{'wget'} = 0;
			set_downloader();
		},
		'44' => sub {
			$dl{'curl'} = 0;
			$dl{'fetch'} = 0;
			$dl{'wget'} = 0;
			set_downloader();
		}
		);
		if ($alts{$arg}){
			$alts{$arg}->();
		}
		else {
			error_handler('bad-arg', $opt, $arg);
		}
		# print "alt $arg\n"; 
		},
	'debug:i' => sub { 
		my ($opt,$arg) = @_;
		if ($arg =~ /^[1-3]|[1-2][0-2]$/){
			$debug=$arg;
		}
		else {
			error_handler('bad-arg', $opt, $arg);
		} },
	'display:s' => sub { 
		my ($opt,$arg) = @_;
		if ($arg =~ /^:?[0-9]+$/){
			$display=$arg;
		}
		else {
			error_handler('bad-arg', $opt, $arg);
		} },
	'downloader:s' => sub { 
		my ($opt,$arg) = @_;
		$arg = lc($arg);
		if ($arg =~ /^(curl|fetch|ftp|perl|wget)$/){
			# this dumps all the other data and resets %dl for only the
			# desired downloader.
			$arg = set_perl_downloader($arg);
			%dl = ('dl' => $arg, $arg => 1);
			set_downloader();
		}
		else {
			error_handler('bad-arg', $opt, $arg);
		} },
	'ftp:s'  => sub { 
		my ($opt,$arg) = @_;
		# pattern: ftp.x.x/x
		if ($arg =~ /^ftp\..+\..+\/[^\/]+$/ ){
			$ftp_alt = $arg;
		}
		else {
			error_handler('bad-arg', $opt, $arg);
		}},
	'<>' => sub {
		my ($opt) = @_;
		error_handler('unknown-option', "$opt", "" ); }
	) ; #or error_handler('unknown-option', "@ARGV", '');
} 
