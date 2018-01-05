#!/usr/bin/perl
## File: start_client.pl
## Version: 1.5
## Date 2018-01-04
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

sub log_data {}

# args: 1 - desktop/app command for --version; 2 - search string; 
# 3 - space print number; 4 - [optional] version arg: -v, version, etc
sub program_version {
	my ($app, $search, $num,$version,$exit) = @_;
	my ($cmd,$line,$output);
	my $version_nu = '';
	my $count = 0;
	$exit ||= 100; # basically don't exit ever
	$version ||= '--version';
	# adjust to array index, not human readable
	if ( $num > 0 ){
		$num--;
	}
	# dump these once the dm stuff is done, we'll pass this data
	if ( $app =~ /^dwm|ksh|scrotwm|spectrwm$/ ) {
		$version = '-v';
	}
	elsif ($app eq 'epoch' ){
		$version = 'version';
	}
	# note, some wm/apps send version info to stderr instead of stdout
	if ( $app =~ /^dwm|ksh|kvirc|scrotwm$/ ) {
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
	log_data("version: $version num: $num search: $search command: $cmd");
	$output = qx($cmd);
	# sample: dwm-5.8.2, ©.. etc, why no space? who knows. Also get rid of v in number string
	# xfce, and other, output has , in it, so dump all commas and parentheses
	if ($output){
		open my $ch, '<', \$output or die "failed to open: error: $!";
		while (<$ch>){
			#chomp;
			last if $count > $exit;
			if ( $_ =~ /$search/i ) {
				$_ = trimmer($_);
				# print "$_ ::$num\n";
				$version_nu = (split /\s+/, $_)[$num];
				$version_nu =~ s/(,|dwm-|wmii2-|wmii-|v|V|\(|\))//g;
				# print "$version_nu\n";
				last;
			}
			$count++;
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
my @ps_aux;
sub set_ps_aux {
	return 1 if @ps_aux;
	@ps_aux = data_grabber('ps aux');
	$_=lc for @ps_aux;
}

my %client = (
'console' => 0,
'dcop' => 0,
'konvi' => 0,
'name' => '',
'name-print' => '',
'native' => 1,
'qdbus' => 1,
'version' => '',
);
my %show = (
'filter-override' => 0,

);
my (@app);
my $start = '';
my $end = '';
my $b_irc = 1;
my $bsd_type = '';

## real code

{
package StartClient;

# use warnings;
# use strict;

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
	$ppid = getppid();
	if (!$b_irc){
		my $string = qx(ps -p $ppid -o comm= 2>/dev/null);
		chomp($string);
		if ($string){
			$client{'name'} = lc($string);
			$client{'name-print'} = "$string shell";
		}
		else {
			$client{'name'} = 'shell';
			$client{'name-print'} = 'Shell';
		}
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
	my $client_name = '';
	
	# print "$ppid\n";
	if ($ppid && -e "/proc/$ppid/exe" ){
		$client_name = lc(readlink "/proc/$ppid/exe");
		$client_name =~ s/.*\///;
		if ($client_name =~ /^bash|dash|sh|python.*|perl.*$/){
			$pppid = (main::data_grabber("ps -p $ppid -o ppid 2>/dev/null"))[1];
			#my @temp = (main::data_grabber("ps -p $ppid -o ppid 2>/dev/null"))[1];
			$pppid =~ s/^\s+|\s+$//g;
			$client_name =~ s/[0-9\.]+$//; # clean things like python2.7
			if ($pppid && -f "/proc/$pppid/exe" ){
				$client_name = lc(readlink "/proc/$pppid/exe");
				$client_name =~ s/.*\///;
				$client{'native'} = 0;
			}
		}
		$client{'name'} = $client_name;
		get_client_version();
		# print "c:$client_name p:$pppid\n";
	}
	else {
		if (! check_modern_konvi() ){
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
			$client_name =~ s/[0-9\.]+$//; # clean things like python2.7
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
	@app = client_values($client{'name'});
	my (@data,$string);
	if (@app){
		$string = ($client{'name'} =~ /^gribble|limnoria|supybot$/) ? 'supybot' : $client{'name'};
		$client{'version'} = main::program_version($string,$app[0],$app[1],$app[2]);
		$client{'name-print'} = $app[3];
		$client{'console-irc'} = $app[4];
	}
	if ($client{'name'} =~ /^bash|dash|sh$/ ){
		$client{'name-print'} = 'shell wrapper';
		$client{'console-irc'} = 1;
	}
	elsif ($client{'name'} eq 'bitchx') {
		@data = data_grabber("$client{'name'} -v");
		$string = (grep {$_ =~ /Version/} @data)[0];
		$string =~ s/[()]|bitchx-//g; 
		@data = split /\s+/, $string;
		$_=lc for @data;
		$client{'version'} = ($data[1] eq 'version') ? $data[2] : $data[1];
	}
	# 'hexchat' => ['',0,'','HexChat',0,0], # special
	# the hexchat author decided to make --version/-v return a gtk dialogue box, lol...
	# so we need to read the actual config file for hexchat. Note that older hexchats
	# used xchat config file, so test first for default, then legacy. Because it's possible
	# for this file to be user edited, doing some extra checks here.
	elsif ($client{'name'} eq 'hexchat') {
		if ( -f '~/.config/hexchat/hexchat.conf' ){
			@data = main::reader('~/.config/hexchat/hexchat.conf');
		}
		elsif ( -f '~/.config/hexchat/xchat.conf' ){
			@data = main::reader('~/.config/hexchat/xchat.conf');
		}
		if (@data){
			foreach (@data){
				$_ = trimmer($_);
				$client{'version'} = ( grep { last if $_ =~ /version/i } split /\s*=\s*/, $_)[1];
				last if $client{'version'};
			}
		}
		$client{'name-print'} = 'HexChat';
	}
	# note: see legacy inxi konvi logic if we need to restore any of the legacy code.
	elsif ($client{'name'} eq 'konversation') {
		$client{'konvi'} = ( ! $client{'native'} ) ? 2 : 1;
	}
	elsif ($client{'name'} =~ /quassel/) {
		@data = data_grabber("$client{'name'} -v 2>/dev/null");
		foreach (@data){
			if ($_ =~ /^Quassel IRC:/){
				$client{'version'} = (split /\s+/, $_ )[2];
				last;
			}
			elsif ($_ =~ /quassel\s[v]?[0-9]/){
				$client{'version'} = (split /\s+/, $_ )[1];
				last;
			}
		}
		$client{'version'} ||= '(pre v0.4.1)?'; 
	}
	# then do some perl type searches, do this last since it's a wildcard search
	elsif ($client{'name'} =~ /^perl.*|ksirc|dsirc$/ ) {
		my @cmdline = get_cmdline();
		# Dynamic runpath detection is too complex with KSirc, because KSirc is started from
		# kdeinit. /proc/<pid of the grandparent of this process>/exe is a link to /usr/bin/kdeinit
		# with one parameter which contains parameters separated by spaces(??), first param being KSirc.
		# Then, KSirc runs dsirc as the perl irc script and wraps around it. When /exec is executed,
		# dsirc is the program that runs inxi, therefore that is the parent process that we see.
		# You can imagine how hosed I am if I try to make inxi find out dynamically with which path
		# KSirc was run by browsing up the process tree in /proc. That alone is straightjacket material.
		# (KSirc sucks anyway ;)
		foreach (@cmdline){
			if ( $_ =~ /dsirc/ ){
				$client{'version'} = main::program_version('ksirc','KSirc:',2,'-v',0);
				$client{'name'} = 'ksirc';
				$client{'name-print'} = 'KSirc';
			}
		}
		$client{'console-irc'} = 1;
		perl_python_client();
	}
	elsif ($client{'name'} =~ /python/) {
		perl_python_client();
	}
	if (!$client{'name-print'}) {
		$client{'name-print'} = 'Unknown Client: ' . $client{'name'};
	}
	eval $end;
}
# returns array of:
# 0 - match string; 1 - search number; 2 - version string; 3 - Print name
# 4 - console 0/1; 5 - 0/1 exit version loop at first iteration
sub client_values {
	my $name = shift;
	my (@client_data,$ref);
	my %data = (
	'bitchx' => ['bitchx',2,'','BitchX',1,0],# special
	'finch' => ['finch',2,'-v','Finch',1,1],
	'gaim' => ['[0-9.]+',2,'-v','Gaim',0,1],
	'ircii' => ['[0-9.]+',3,'-v','ircII',1,1],
	'irssi' => ['irssi',2,'-v','Irssi',1,1],
	'irssi-text' => ['irssi',2,'-v','Irssi',1,1],
	'konversation' => ['konversation',2,'-v','Konversation',0],
	'kopete' => ['Kopete',2,'-v','Kopete',0,0],
	'kvirc' => ['[0-9.]+',2,'-v','KVIrc',0,0], # special
	'pidgin' => ['[0-9.]+',2,'-v','Pidgin',0,1],
	'quassel' => ['',1,'-v','Quassel [M]',0,0], # special
	'quasselclient' => ['',1,'-v','Quassel',0,0],# special
	'quasselcore' => ['',1,'-v','Quassel (core)',0,0],# special
	'gribble' => ['^Supybot',2,'--version','Gribble',1,0],# special
	'limnoria' => ['^Supybot',2,'--version','Limnoria',1,0],# special
	'supybot' => ['^Supybot',2,'--version','Supybot',1,0],# special
	'weechat' => ['[0-9.]+',1,'-v','WeeChat',1,0],
	'weechat-curses' => ['[0-9.]+',1,'-v','WeeChat',1,0],
	'xchat-gnome' => ['[0-9.]+',2,'-v','X-Chat-Gnome',1,1],
	'xchat' => ['[0-9.]+',2,'-v','X-Chat',1,1],
	);
	if ( defined $data{$name} ){
		$ref = $data{$name};
		@client_data = @$ref;
	}
	#my $debug = main::Dumper \@client_data;
	# main::log_data("Client Data: " . main::Dumper \@client_data);
	return @client_data;
}
sub get_cmdline {
	eval $start;
	my @cmdline;
	my $i = 0;
	$ppid = getppid();
	if (! -e "/proc/$ppid/cmdline" ){
		return 1;
	}
	local $\ = '';
	open( my $fh, '<', "/proc/$ppid/cmdline" ) or 
	  print_line("Open /proc/$ppid/cmdline failed: $!");
	my @rows = <$fh>;
	close $fh;
	
	foreach (@rows){
		push @cmdline, $_;
		$i++;
		last if $i > 31;
	}
	if ( $i == 0 ){
		$cmdline[0] = $rows[0];
		$i = ($cmdline[0]) ? 1 : 0;
	}
	main::log_data("cmdline: @cmdline count: $i");
	eval $end;
	return @cmdline;
}
sub perl_python_client {
	eval $start;
	return 1 if $client{'version'};
	main::set_ps_aux();
	# this is a hack to try to show konversation if inxi is running but started via /cmd
	# OR via script shortcuts, both cases in fact now
	# main::print_line("konvi: " . scalar grep { $_ =~ /konversation/ } @ps_aux);
	if ( $b_display && ( scalar grep { $_ =~ /konversation/ } @ps_aux ) > 0){
		@app = client_values('konversation');
		$client{'version'} = main::program_version('konversation',$app[0],$app[1],$app[2]);
		$client{'name'} = 'konversation';
		$client{'name-print'} = $app[3];
		$client{'console-irc'} = $app[4];
	}
	## NOTE: supybot only appears in ps aux using 'SHELL' command; the 'CALL' command
	## gives the user system irc priority, and you don't see supybot listed, so use SHELL
	elsif ( !$b_display && ( scalar grep { $_ =~ /supybot/ } @ps_aux ) > 0  ){
		@app = client_values('supybot');
		$client{'version'} = main::program_version('supybot',$app[0],$app[1],$app[2]);
		if ($client{'version'}){
			if ( ( scalar grep { $_ =~ /gribble/i } @ps_aux ) > 0){
				$client{'name'} = 'gribble';
				$client{'name-print'} = 'Gribble';
			}
			if ( ( scalar grep { $_ =~ /limnoria/i } @ps_aux ) > 0){
				$client{'name'} = 'limnoria';
				$client{'name-print'} = 'Limnoria';
			}
			else {
				$client{'name'} = 'supybot';
				$client{'name-print'} = 'Supybot';
			}
		}
		else {
			$client{'name'} = 'supybot';
			$client{'name-print'} = 'Supybot';
		}
		$client{'console-irc'} = 1;
	}
	else {
		$client{'name-print'} = "Unknown $client{'name'} client";
	}
	main::log_data("namep: $client{'name-print'} name: $client{'name'} version: $client{'version'}");
	eval $end;
}
## try to infer the use of Konversation >= 1.2, which shows $PPID improperly
## no known method of finding Konvi >= 1.2 as parent process, so we look to see if it is running,
## and all other irc clients are not running. As of 2014-03-25 this isn't used in my cases
sub check_modern_konvi {
	eval $start;
	
	return 0 if ! $client{'qdbus'};
	my $b_modern_konvi = 0;
	my $konvi_version = '';
	my $konvi = '';
	my $pid = '';
	my (@temp);
	# main::log_data("name: $client{'name'} :: qdb: $client{'qdbus'} :: version: $client{'version'} :: konvi: $client{'konvi'} :: PPID: $ppid");
	# sabayon uses /usr/share/apps/konversation as path
	if ( -d '/usr/share/kde4/apps/konversation' || -d '/usr/share/apps/konversation' ){
		$pid = (grep { $_ =~ /konversation/i } main::data_grabber('ps -A'))[0];
		main::log_data("pid: $pid");
		$pid =~ s/^\s|\s$//g;
		$pid = (split /\s+/, $pid)[0];
		$konvi = readlink ("/proc/$pid/exe");
		$konvi =~ s/.*\///; # basename
		@app = client_values('konversation');
		if ($konvi){
			@app = client_values('konversation');
			$konvi_version = main::program_version($konvi,$app[0],$app[1],$app[2]);
			@temp = split /\./, $konvi_version;
			$client{'console-irc'} = $app[4];
			$client{'konvi'} = 3;
			$client{'name'} = 'konversation';
			$client{'name-print'} = $app[3];
			$client{'version'} = $konvi_version;
			# note: we need to change this back to a single dot number, like 1.3, not 1.3.2
			$konvi_version = $temp[0] . "." . $temp[1];
			if ($konvi_version > 1.1){
				$b_modern_konvi = 1;
			}
		}
	}
	main::log_data("name: $client{'name'} name print: $client{'name-print'} 
	qdb: $client{'qdbus'} version: $konvi_version konvi: $konvi PID: $pid");
	main::log_data("b_is_qt4: $b_modern_konvi");
	## for testing this module
# 	my $ppid = getppid();
# 	system('qdbus org.kde.konversation', '/irc', 'say', $client{'dserver'}, $client{'dtarget'}, 
# 	"getpid_dir: $konvi_qt4 verNum: $konvi_version pid: $pid ppid: $ppid" );
	eval $end;
	return $b_modern_konvi;
}

sub set_konvi_data {
	eval $start;
	my $config_tool = '';
	# https://userbase.kde.org/Konversation/Scripts/Scripting_guide
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
