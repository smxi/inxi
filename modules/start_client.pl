#!/usr/bin/perl
## File: start_client.pl
## Version: 1.1
## Date 2018-01-03
## License: GNU GPL v3 or greater
## Copyright (C) 2017-18 Harald Hope

my $self_name='pinxi';
my $self_version='2.9.00';
my $self_date='2018-01-03';
my $self_patch='048-p';

use strict;
use warnings;
# use diagnostics;
use 5.008;

# use File::Basename;

## stub code


my $start = '';
my $end = '';

sub log_data {}

sub program_version {
	my ($app, $search, $num) = @_;
	my ($cmd,$line,$output);
	my $version_nu = '';
	my $version = '--version';
	if ( $num > 0 ){
		$num--;
	}
	if ( $app =~ /^dwm|konversation|ksh|scrotwm|spectrwm$/ ) {
		$version = '-v';
	}
	elsif ($app eq 'epoch' ){
		$version = 'version';
	}
	# note, some wm/apps send version info to stderr instead of stdout
	if ( $app =~ /^dwm|ksh|scrotwm$/ ) {
		$cmd = "$app $version 2>&1";
	}
	elsif ( $app eq 'csh' ){
		$cmd = "tcsh $version 2>/dev/null";
	}
	# quick debian/buntu hack until I find a universal way to get version for these
	elsif ( $app eq 'dash' ){
		$cmd = "dpkg -l $app 2>/dev/null";
	}
	else {
		$cmd = "$app $version 2>/dev/null";
	}
	log_data("app version command: $cmd");
	$output = qx($cmd);
	# sample: dwm-5.8.2, ©.. etc, why no space? who knows. Also get rid of v in number string
	# xfce, and other, output has , in it, so dump all commas and parentheses
	if ($output){
		open my $ch, '<', \$output or die "failed to open: error: $!";
		while (<$ch>){
			#chomp;
			if ( $_ =~ /$search/i ) {
				$_ = trimmer($_);
				# print "$_ ::$num\n";
				$version_nu = (split /\s+/, $_)[$num];
				$version_nu =~ s/(,|dwm-|wmii2-|wmii-|v|V|\(|\))//g;
				# print "$version_nu\n";
				last;
			}
		}
		close $ch if $ch;
	}
	log_data("Program version: $version_nu");
	return $version_nu;
}
## returns result of test, 0/1, false/true
## arg: program to find in PATH
sub check_program {
	grep { -x "$_/$_[0]"}split /:/,$ENV{PATH};
}

sub trimmer {
	my $str = shift;
	$str =~ s/^\s+|\s+$|\n$//g; 
	return $str;
}
# arg: 1 - command to turn into an array; 2 - optional: splitter
# similar to reader() except this creates an array of data 
# by lines from the command arg
sub data_grabber {
	my ($command,$splitter) = @_;
	$splitter ||= "\n";
	return split /$splitter/, qx($command);
}
# arg: 1 - full file path, returns array of file lines.
sub reader {
	my $file = shift;
	open( my $fh, '<', $file ) or error_handler('open', $file, $!);
	my @rows = <$fh>;
	close $fh;
	return @rows;
}

my %client = (
'console' => 0,
'dcop' => 0,
'konvi' => 0,
'name' => '',
'native' => 1,
'qdbus' => 1,
'version' => '',
);
my %show = (
'filter-override' => 0,

);

my $b_irc = 1;
my $bsd_type = '';

## real code

{
package StartClient;

# use warnings;
# use strict;

my $client_name = '';
my $ppid = '';
my $pppid = '';

# args: none
sub new {
	my $class = shift;
	my $self = {};
	# print "$f\n";
	# print "$type\n";
	return bless $self, $class;
}

sub get_client_data {
	eval $start;
	if (!$b_irc){
		$client{'name'} = 'shell';
	}
	else {
		$show{'filter-output'} = (!$show{'filter-override'}) ? 1 : 0;
		get_client_name();
		if ($client{'konvi'} == 1 || $client{'konvi'} == 3){
			set_konvi_data();
		}
	}
	eval $end;
}
sub get_client_name {
	eval $start;
	$ppid = getppid();
	# print "$ppid\n";
	if ($ppid && -e "/proc/$ppid/exe" ){
		$client_name = lc(readlink "/proc/$ppid/exe");
		$client_name =~ s/.*\///;
		if ($client_name =~ /^bash|dash|sh|python.*|perl.*$/){
			$pppid = (main::data_grabber("ps -p $ppid -o ppid 2>/dev/null"))[1];
			#my @temp = (main::data_grabber("ps -p $ppid -o ppid 2>/dev/null"))[1];
			$pppid =~ s/^\s+|\s+$//g;
			$client_name =~ s/[0-9.]+$//; # clean things like python2.7
			if ($pppid && -f "/proc/$pppid/exe" ){
				$client_name = lc(readlink "/proc/$pppid/exe");
				$client_name =~ s/.*\///;
				$client{'native'} = 0;
				
			}
		}
		$client{'name'} = $client_name;
		# check_qt4_konvi();
		get_client_version();
		# set_konvi_data();
		# print "c:$client_name p:$pppid\n";
	}
	else {
		if (! check_qt4_konvi() ){
			$ppid = getppid();
			$client_name = (main::data_grabber("ps -p $ppid 2>/dev/null"))[1];
			my @data = split /\s+/, $client_name;
			if ($bsd_type){
				$client_name = lc($data[5]);
			}
			# gnu/linux uses last value
			else {
				$client_name = lc($data[scalar @data - 1]);
			}
			$client_name =~ s/.*\|-(|)//;
			if ($client_name){
				$client{'name'} = $client_name;
				$client{'native'} = 1;
				get_client_version();
			}
			else {
				$client{'name'} = "PPID='$ppid' - Empty?";
			}
		}
	}
	main::log_data("Client: $client{'name'} :: version: $client{'version'} :: konvi: $client{'konvi'} :: PPID: $ppid");
	eval $end;
}
sub get_client_version {
	eval $start;
	if ($client{'name'} eq 'python') {
		perl_python_client();
	}
	eval $end;
}
sub perl_python_client {
	eval $start;
	eval $end;
}
## try to infer the use of Konversation >= 1.2, which shows $PPID improperly
## no known method of finding Konvi >= 1.2 as parent process, so we look to see if it is running,
## and all other irc clients are not running. As of 2014-03-25 this isn't used in my cases
sub check_qt4_konvi {
	eval $start;
	
	return 0 if ! $client{'qdbus'};
	my $b_qt4_konvi = 0;
	my $konvi_version = '';
	my $konvi = '';
	my $pid = '';
	my (@temp);
	# main::log_data("name: $client{'name'} :: qdb: $client{'qdbus'} :: version: $client{'version'} :: konvi: $client{'konvi'} :: PPID: $ppid");
	# sabayon uses /usr/share/apps/konversation as path
	if ( -d "/usr/share/kde4/apps/konversation" || -d "/usr/share/apps/konversation" ){
		$pid = (grep { $_ =~ /konversation/i } main::data_grabber('ps -A'))[0];
		main::log_data("pid: $pid");
		$pid =~ s/^\s|\s$//g;
		$pid = (split /\s+/, $pid)[0];
		$konvi = readlink ("/proc/$pid/exe");
		$konvi =~ s/.*\///;
		if ($konvi){
			$konvi_version = main::program_version($konvi,$konvi,2);
			@temp = split /\./, $konvi_version;
			$client{'version'} = $konvi_version;
			$client{'konvi'} = 3;
			$client{'name'} = 'konversation';
			# note: we need to change this back to a single dot number, like 1.3, not 1.3.2
			$konvi_version = $temp[0] . "." . $temp[1];
			if ($konvi_version > 1.1){
				$b_qt4_konvi = 1;
			}
		}
	}
	main::log_data("name: $client{'name'} :: qdb: $client{'qdbus'} :: version: $konvi_version :: konvi: $konvi :: PID: $pid");
	main::log_data("b_is_qt4: $b_qt4_konvi");
	## for testing this module
# 	my $ppid = getppid();
# 	system('qdbus org.kde.konversation', '/irc', 'say', $client{'dserver'}, $client{'dtarget'}, 
# 	"getpid_dir: $konvi_qt4 verNum: $konvi_version pid: $pid ppid: $ppid" );
	eval $end;
	return $b_qt4_konvi;
}

sub set_konvi_data {
	eval $start;
	my $config_tool = '';
	my $konvi_config="konversation/scripts/inxi.conf";
	if ( $client{'konvi'} == 3 ){
		$client{'dserver'} = shift @ARGV;
		$client{'dtarget'} = shift @ARGV;
		$client{'dobject'} = 'default';
	}
	elsif ( $client{'konvi'} == 1 ){
		$client{'dport'} = shift @ARGV;
		$client{'dserver'} = shift @ARGV;
		$client{'dtarget'} = shift @ARGV;
		$client{'dobject'} = 'Konversation';
	}
	# for some reason this logic hiccups on multiple spaces between args
	@ARGV = grep { $_ ne '' } @ARGV;
	# there's no current kde 5 konvi config tool that we're aware of. Correct if changes.
	if ( main::check_program('kde4-config') ){
		$config_tool = 'kde4-config';
	}
	elsif ( main::check_program('kde5-config') ){
		$config_tool = 'kde5-config';
	}
	elsif ( main::check_program('kde-config') ){
		$config_tool = 'kde-config';
	}
	# The section below is on request of Argonel from the Konversation developer team:
	# it sources config files like $HOME/.kde/share/apps/konversation/scripts/inxi.conf
	if ($config_tool){
		my @data = main::data_grabber("$config_tool --path data 2>/dev/null",':');
		main::get_configs(@data);
	}
	eval $end;
}
}1;

my $ob_start = StartClient->new();
$ob_start->get_client_data();
