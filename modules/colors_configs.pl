#!/usr/bin/perl
## File: colors_configs.pl
## Version: 1.4
## Date 2018-01-02
## License: GNU GPL v3 or greater
## Copyright (C) 2017 Harald Hope

use strict;
use warnings;
# use diagnostics;
use 5.008;

use Data::Dumper qw(Dumper); # print_r

my $self_name='pinxi';
my $self_version='2.9.00';
my $self_date='2017-12-31';
my $self_patch='037-p';
my $self_path = "$ENV{'HOME'}/bin/scripts/inxi/svn/branches/inxi-perl";
my $user_config_dir= "$ENV{'HOME'}/.config";
my $user_config_file;
## stub code

my (%client,%colors,%size);
$size{'max'} = 90;
$client{'konvi'} = 0;
$client{'test-konvi'} = 0;
$colors{'default'} = 2;
$colors{'selector'} = 94;
my $b_irc = 0;
my $start = '';
my $end = '';
my $b_display = 1;
my $output_type = 'print-basic';
my $line1 = "----------------------------------------------------------------------\n";

sub error_handler {
	my ( $err, $one, $two) = @_;
	print "$err $one\n";
	exit 0;
}

sub print_line {
	my $line = shift;
	if ($client{'test-konvi'}){
		$client{'konvi'} = 3;
		$client{'qdbus'} = 1;
		$client{'dcop'} = 0;
		$client{'dobject'} = 'Konversation';
	}
	if ( $client{'konvi'} == 1 && $client{'dcop'} ){
		# konvi doesn't seem to like \n characters, it just prints them literally
		$line =~ s/\n//g;
		#qx('dcop "$client{'dport'}" "$client{'dobject'}" say "$client{'dserver'}" "$client{'dtarget'}" "$line 1");
		system('dcop', $client{'dport'}, $client{'dobject'}, 'say', $client{'dserver'}, $client{'dtarget'}, "$line 1");
	}
	elsif ($client{'konvi'} == 3 && $client{'qdbus'} ){
		# print $line;
		$line =~ s/\n//g;
		#qx(qdbus org.kde.konversation /irc say "$client{'dserver'}" "$client{'dtarget'}" "$line");
		system('qdbus', 'org.kde.konversation', '/irc', 'say', $client{'dserver'}, $client{'dtarget'}, $line);
	}
	else {
		print $line;
	}
}

sub print_basic {
	my @data = @_;
	my $indent = 18;
	my $indent_static = 18;
	my $indent1_static = 5;
	my $indent2_static = 8;
	my $indent1 = 5;
	my $indent2 = 8;
	my $length =  @data;
	my ($start,$aref,$i,$j,$line, $word);
	
	if ( $size{'max'} > 110 ){
		$indent_static = 22;
	}
	elsif ($size{'max'} < 90 ){
		$indent_static = 15;
	}
	# print $length . "\n";
	for $i (0 .. $#data){
		$aref = $data[$i];
		#print "0: $data[$i][0]\n";
		if ($data[$i][0] == 0 ){
			$indent = 0;
			$indent1 = 0;
			$indent2 = 0;
		}
		elsif ($data[$i][0] == 1 ){
			$indent = $indent_static;
			$indent1 = $indent1_static;
			$indent2= $indent2_static;
		}
		elsif ($data[$i][0] == 2 ){
			$indent = ( $indent_static + 7 );
			$indent1 = ( $indent_static + 5 );
			$indent2 = 0;
		}
		$data[$i][3] =~ s/\n/ /g;
		$data[$i][3] =~ s/\s+/ /g;
		if ($data[$i][1] && $data[$i][2]){
			$data[$i][1] = $data[$i][1] . ', ';
		}
		$start = sprintf("%${indent1}s%-${indent2}s",$data[$i][1],$data[$i][2]);
		if ($indent > 1 && ( length($start) > ( $indent - 1) ) ){
			$line = sprintf("%-${indent}s\n", "$start");
			print_line($line);
			$start = '';
		}
		if ( ( $indent + length($data[$i][3]) ) < $size{'max'} ){
			$data[$i][3] =~ s/\^/ /g;
			$line = sprintf("%-${indent}s%s\n", "$start", $data[$i][3]);
			print_line($line);
		}
		else {
			my $holder = '';
			my $sep = ' ';
			foreach $word (split / /, $data[$i][3]){
				#print "$word\n";
				if ( ( $indent + length($holder) + length($word) ) < $size{'max'} ) {
					$word =~ s/\^/ /g;
					$holder = $holder . $word . $sep;
				}
				elsif ( ( $indent + length($holder) + length($word) ) > $size{'max'}){
					$line = sprintf("%-${indent}s%s\n", "$start", $holder);
					print_line($line);
					$start = '';
					$word =~ s/\^/ /g;
					$holder = $word . $sep;
				}
			}
			if ($holder !~ /^[ ]*$/){
				$line = sprintf("%-${indent}s%s\n", "$start", $holder);
				print_line($line);
			}
		}
	}
}

sub reader {
	my $file = shift;
	open( my $fh, "<", $file ) or error_handler('open', $file, $!);
	my @rows = <$fh>;
	return @rows;
}

## start working code

sub check_config_file {
	$user_config_file = "$user_config_dir/$self_name.conf";
	if ( ! -f $user_config_file ){
		open( my $fh, '>', $user_config_file ) or error_handler('create', $user_config_file, $!);
		close $fh;
	}
}

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

sub set_color_scheme {
	eval $start;
	$colors{'scheme'} = shift;
	my $index = ( $b_irc ) ? 1 : 0; # defaults to non irc
	
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
	my @scheme = get_color_scheme($colors{'scheme'});
	$colors{'c1'} = $color_palette{$scheme[0]}[$index];
	$colors{'c2'} = $color_palette{$scheme[1]}[$index];
	$colors{'cn'} = $color_palette{$scheme[2]}[$index];
	# print Dumper \@scheme;
	# print "$colors{'c1'}here$colors{'c2'} we are!$colors{'cn'}\n";
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
		my $ob_selector = SelectColors->new($colors{'selector'});
		$ob_selector->select_schema();
		return 1;
	}
	# set the default, then override as required
	my $color_scheme = $colors{'default'};
	# these are set in user configs
	if (defined $colors{'global'}){
		$color_scheme = $colors{'global'};
	}
	else {
		if ( $b_irc ){
			if (defined $colors{'irc-virt-term'} && $b_display && $client{'console-irc'}){
				$color_scheme = $colors{'irc-virt-term'};
			}
			elsif (defined $colors{'irc-console'} && !$b_display){
				$color_scheme = $colors{'irc-console'};
			}
			elsif ( defined $colors{'irc-gui'}) {
				$color_scheme = $colors{'irc-gui'};
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

{
package SelectColors;

use warnings;
use strict;
use diagnostics;
use 5.008;

my (@data,@rows,%configs,%status);
my ($type,$w_fh);
my $safe_color_count = 12; # null/normal + default color group
my $count = 0;

# args: 1 - type
sub new {
	my $class = shift;
	($type) = @_;
	my $self = {};
	return bless $self, $class;
}
sub select_schema {
	eval $start;
	assign_selectors();
	main::set_color_scheme(0);
	set_status();
	start_selector();
	create_color_selections();
	if (! $b_irc ){
		main::check_config_file();
		get_selection();
	}
	else {
		print_irc_message();
	}
	eval $end;
}

sub set_status {
	$status{'console'} = (defined $colors{'console'}) ? "Set: $colors{'console'}" : 'Unset';
	$status{'virt-term'} = (defined $colors{'virt-term'}) ? "Set: $colors{'virt-term'}" : 'Unset';
	$status{'irc-console'} = (defined $colors{'irc-console'}) ? "Set: $colors{'irc-console'}" : 'Unset';
	$status{'irc-gui'} = (defined $colors{'irc-gui'}) ? "Set: $colors{'irc-gui'}" : 'Unset';
	$status{'irc-virt-term'} = (defined $colors{'irc-virt-term'}) ? "Set: $colors{'irc-virt-term'}" : 'Unset';
	$status{'global'} = (defined $colors{'global'}) ? "Set: $colors{'global'}" : 'Unset';
}

sub assign_selectors {
	if ($type == 94){
		$configs{'variable'} = 'CONSOLE_COLOR_SCHEME';
		$configs{'selection'} = 'console';
	}
	elsif ($type == 95){
		$configs{'variable'} = 'VIRT_TERM_COLOR_SCHEME';
		$configs{'selection'} = 'virt-term';
	}
	elsif ($type == 96){
		$configs{'variable'} = 'IRC_COLOR_SCHEME';
		$configs{'selection'} = 'irc-gui';
	}
	elsif ($type == 97){
		$configs{'variable'} = 'IRC_X_TERM_COLOR_SCHEME';
		$configs{'selection'} = 'irc-virt-term';
	}
	elsif ($type == 98){
		$configs{'variable'} = 'IRC_CONS_COLOR_SCHEME';
		$configs{'selection'} = 'irc-console';
	}
	elsif ($type == 99){
		$configs{'variable'} = 'GLOBAL_COLOR_SCHEME';
		$configs{'selection'} = 'global';
	}
}
sub start_selector {
	my $whoami = getpwuid($<) || "unknown???";
	if ( ! $b_irc ){
		@data = (
		[ 0, '', '', "Welcome to $self_name! Please select the default 
		$configs{'selection'} color scheme."],
		);
	}
	@rows = (
	[ 0, '', '', "Because there is no way to know your $configs{'selection'}
	foreground/background colors, you can set your color preferences from 
	color scheme option list below:"],
	[ 0, '', '', "0 is no colors; 1 is neutral."],
	[ 0, '', '', "After these, there are 4 sets:"],
	[ 0, '', '', "1-dark^or^light^backgrounds; 2-light^backgrounds; 
	3-dark^backgrounds; 4-miscellaneous"],
	[ 0, '', '', ""],
	);
	push @data, @rows;
	if ( ! $b_irc ){
		@rows = (
		[ 0, '', '', "Please note that this will set the $configs{'selection'} 
		preferences only for user: $whoami"],
		);
		push @data, @rows;
	}
	@rows = (
	[ 0, '', '', "$line1"],
	);
	push @data, @rows;
	main::print_basic(@data); 
	@data = ();
}

sub create_color_selections {
	my $spacer = '^^'; # printer removes double spaces, but replaces ^ with ' '
	my $i=0;
	$count = ( main::get_color_scheme('count') - 1 );
	for $i (0 .. $count){
		if ($i > 9){
			$spacer = '^';
		}
		if ($configs{'selection'} =~ /^global|irc-gui|irc-console|irc-virt-term$/ && $i > $safe_color_count ){
			last;
		}
		main::set_color_scheme($i);
		@rows = (
		[0, '', '', "$i)$spacer$colors{'c1'}Card:$colors{'c2'}^nVidia^GT218 
		$colors{'c1'}Display^Server$colors{'c2'}^x11^(X.Org^1.7.7)$colors{'cn'}"],
		);
		push @data, @rows;
	}
	main::print_basic(@data); 
	@data = ();
	main::set_color_scheme(0);
}
sub get_selection {
	my $number = $count + 1;
	@data = (
	[0, '', '', ($number++) . ")^Remove all color settings. Restore $self_name default."],
	[0, '', '', ($number++) . ")^Continue, no changes or config file setting."],
	[0, '', '', ($number++) . ")^Exit, use another terminal, or set manually."],
	[0, '', '', "$line1"],
	[0, '', '', "Simply type the number for the color scheme that looks best to your 
	eyes for your $configs{'selection'} settings and hit <ENTER>. NOTE: You can bring this 
	option list up by starting $self_name with option: -c plus one of these numbers:"],
	[0, '', '', "94^(console,^not^in^desktop^-^$status{'console'}); 
	95^(terminal,^desktop^-^$status{'virt-term'}); 
	96^(irc,^gui,^desktop^-^$status{'irc-gui'}); 
	97^(irc,^desktop,^in^terminal^-^$status{'irc-virt-term'}); 
	98^(irc,^not^in^desktop^-^$status{'irc-console'}); 
	99^(global^-^$status{'global'})"],
	[0, '', '',  ""],
	[0, '', '', "Your selection(s) will be stored here: $user_config_file"],
	[0, '', '', "Global overrides all individual color schemes. Individual 
	schemes remove the global setting."],
	[0, '', '', "$line1"],
	);
	main::print_basic(@data); 
	@data = ();
	my $response = <STDIN>;
	chomp $response;
	if ($response =~ /[^0-9]/ || $response > ($count + 3)){
		@data = (
		[0, '', '', "Error - Invalid Selection. You entered this: $response. Hit <ENTER> to continue."],
		[0, '', '',  "$line1"],
		);
		main::print_basic(@data); 
		my $response = <STDIN>;
		start_selector();
		create_color_selections();
		get_selection();
	}
	else {
		process_selection($response);
	}
}
sub process_selection {
	my $response = shift;
	if ($response == ($count + 3) ){
		@data = ([0, '', '', "Ok, exiting $self_name now. You can set the colors later."],);
		main::print_basic(@data); 
		exit 1;
	}
	elsif ($response == ($count + 2)){
		@data = ([0, '', '', "Ok, continuing $self_name unchanged. You can set the colors 
		anytime by starting with: -c 95 to 99"],);
		main::print_basic(@data); 
		if ( defined $colors{'console'} && !$b_display ){
			main::set_color_scheme($colors{'console'});
		}
		if ( defined $colors{'virt-term'} ){
			main::set_color_scheme($colors{'virt-term'});
		}
		else {
			main::set_color_scheme($colors{'default'});
		}
	}
	elsif ($response == ($count + 1)){
		@data = ([0, '', '', "Removing all color settings from config file now..."],);
		main::print_basic(@data); 
		delete_all_config_colors();
		main::set_color_scheme($colors{'default'});
	}
	else {
		main::set_color_scheme($response);
		@data = ([0, '', '', "Updating config file for $configs{'selection'} color scheme now..."],);
		main::print_basic(@data); 
		if ($configs{'selection'} eq 'global'){
			delete_all_config_colors();
		}
		else {
			set_config_color_scheme($response);
		}
	}
}
sub delete_all_config_colors {
	my @file_lines = main::reader($user_config_file);
	open( $w_fh, '>', $user_config_file ) or error_handler('open', $user_config_file, $!);
	foreach ( @file_lines ) { 
		if ( $_ !~ /^(CONSOLE_COLOR_SCHEME|GLOBAL_COLOR_SCHEME|IRC_COLOR_SCHEME|IRC_CONS_COLOR_SCHEME|IRC_X_TERM_COLOR_SCHEME|VIRT_TERM_COLOR_SCHEME)/){
			print {$w_fh} "$_"; 
		}
	} 
	close $w_fh;
}
sub set_config_color_scheme {
	my $value = shift;
	my @file_lines = main::reader($user_config_file);
	my $b_found = 0;
	open( $w_fh, '>', $user_config_file ) or error_handler('open', $user_config_file, $!);
	foreach ( @file_lines ) { 
		if ( $_ =~ /^$configs{'variable'}/ ){
			$_ = "$configs{'variable'}=$value\n";
			$b_found = 1;
		}
		print $w_fh "$_";
	}
	if (! $b_found ){
		print $w_fh "$configs{'variable'}=$value\n";
	}
	close $w_fh;
}

sub print_irc_message {
	@data = (
	[ 0, '', '', "$line1"],
	[ 0, '', '', "After finding the scheme number you like, simply run this again
	in a terminal to set the configuration data file for your irc client. You can 
	set color schemes for the following: start inxi with -c plus:"],
	[ 0, '', '', "94 (console,^not^in^desktop^-^$status{'console'})"],
	[ 0, '', '', "95 (terminal, desktop^-^$status{'virt-term'})"],
	[ 0, '', '', "96 (irc,^gui,^desktop^-^$status{'irc-gui'})"],
	[ 0, '', '', "97 (irc,^desktop,^in terminal^-^$status{'irc-virt-term'})"],
	[ 0, '', '', "98 (irc,^not^in^desktop^-^$status{'irc-console'})"],
	[ 0, '', '', "99 (global^-^$status{'global'})"]
	);
	main::print_basic(@data); 
	exit 1;
}

};1;
# print "Your username is: ", getpwuid($<) || "unknown???", "\n";
# print get_color_scheme('count'), "\n";
# set_color_scheme(30);

# print $temp[0] . " " . $temp[2],"\n";
# 
# print ref $color_schemes[18], "\n";
my $ob_selector = SelectColors->new($colors{'selector'});
$ob_selector->select_schema();


# print "${$color_schemes[18]}[1]\n";
# 
# print Dumper \$temp;

# print "$temp[1]\n";
# 
# print "$co{$temp[0]} hello world $co{$temp[2]}\n";
