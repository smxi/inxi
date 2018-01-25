#!/usr/bin/perl
## File: start_client.pl
## Version: 2.1
## Date 2018-01-14
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
use Time::HiRes qw(gettimeofday tv_interval);
use Data::Dumper qw(Dumper); # print_r

# use File::Basename;

### START DEFAULT CODE ##

my @ps_aux;
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
my $b_display = 1;
my $b_log;
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

### END DEFAULT CODE ##

### START CODE REQUIRED BY THIS MODULE ##

my @ps_cmd;

sub set_ps_aux {
	eval $start if $b_log;
	@ps_aux = split "\n",qx(ps aux);;
	shift @ps_aux; # get rid of header row
	$_=lc for @ps_aux; # this is a super fast way to set to lower
	# this is for testing for the presence of the command
	@ps_cmd = map {
		my @split = split /\s+/, $_;
		# slice out 10th to last elements of ps aux rows
		my $final = $#split;
		# some stuff has a lot of data, chrome for example
		$final = ($final > 12) ? 12 : $final;
		@split = @split[10 .. $final ];
		join " ", @split;
	} @ps_aux;
	eval $end if $b_log;
}
sub get_shell_data {
	eval $start if $b_log;
	my ($ppid) = @_;
	my $shell = qx(ps -p $ppid -o comm= 2>/dev/null);
	chomp($shell);
	if ($shell){
		# when run in debugger subshell, would return sh as shell,
		# and parent as perl, that is, pinxi itself, which is actually right.
		if ($shell eq 'sh' && $shell ne $ENV{'SHELL'}){
			$shell = $ENV{'SHELL'};
			$shell =~ s/^.*\///;
		}
		# sh because -v/--version doesn't work on it, ksh because
		# it takes too much work to handle all the variants
		if ( $shell ne 'sh' && $shell ne 'ksh' ) {
			@app = main::program_values(lc($shell));
			if ($app[0]){
				$client{'version'} = main::program_version($shell,$app[0],$app[1],$app[2]);
			}
			# guess that it's two and --version
			else {
				$client{'version'} = main::program_version($shell,2,'');
			}
			$client{'version'} =~ s/(\(.*|-release|-version)//;
		}
		$client{'name'} = lc($shell);
		$client{'name-print'} = $shell;
	}
	else {
		$client{'name'} = 'shell';
		$client{'name-print'} = 'Unknown Shell';
	}
	eval $end if $b_log;
}

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
# returns array of:
# 0 - match string; 1 - search number; 2 - version string; 3 - Print name
# 4 - console 0/1; 5 - 0/1 exit version loop at first iteration
sub program_values {
	my $name = shift;
	my (@client_data,$ref);
	my %data = (
	# shells
	'bash' => ['^GNU[[:space:]]bash,[[:space:]]version',4,'--version','Bash',1,0],
	'csh' => ['csh',2,'--version','csh',1,0],
	'dash' => ['dash',3,'--version','Dash',1,0],
	'ksh' => ['version',5,'-v','csh',1,0],
	'tcsh' => ['^tcsh',2,'--version','tcsh',1,0],
	'zsh' => ['^zsh',2,'--version','zsh',1,0],
	# clients
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

### START MODULE CODE ##

# StartClient
{
package StartClient;

# use warnings;
# use strict;

my $ppid = '';
my $pppid = '';

# NOTE: there's no reason to crete an object, we can just access
# the features statically. 
# args: none
# sub new {
# 	my $class = shift;
# 	my $self = {};
# 	# print "$f\n";
# 	# print "$type\n";
# 	return bless $self, $class;
# }

sub get_client_data {
	eval $start if $b_log;
	$ppid = getppid();
	main::set_ps_aux() if ! @ps_aux;
	if (!$b_irc){
		main::get_shell_data($ppid);
	}
	else {
		$show{'filter-output'} = (!$show{'filter-override'}) ? 1 : 0;
		get_client_name();
		if ($client{'konvi'} == 1 || $client{'konvi'} == 3){
			set_konvi_data();
		}
	}
	eval $end if $b_log;
}

sub get_client_name {
	eval $start if $b_log;
	my $client_name = '';
	
	# print "$ppid\n";
	if ($ppid && -e "/proc/$ppid/exe" ){
		$client_name = lc(readlink "/proc/$ppid/exe");
		$client_name =~ s/^.*\///;
		if ($client_name =~ /^bash|dash|sh|python.*|perl.*$/){
			$pppid = (main::grabber("ps -p $ppid -o ppid"))[1];
			#my @temp = (main::grabber("ps -p $ppid -o ppid 2>/dev/null"))[1];
			$pppid =~ s/^\s+|\s+$//g;
			$client_name =~ s/[0-9\.]+$//; # clean things like python2.7
			if ($pppid && -f "/proc/$pppid/exe" ){
				$client_name = lc(readlink "/proc/$pppid/exe");
				$client_name =~ s/^.*\///;
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
			$client_name = (main::grabber("ps -p $ppid"))[1];
			
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
	main::log_data("Client: $client{'name'} :: version: $client{'version'} :: konvi: $client{'konvi'} :: PPID: $ppid") if $b_log;
	eval $end if $b_log;
}
sub get_client_version {
	eval $start if $b_log;
	@app = main::program_values($client{'name'});
	my (@data,@working,$string);
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
		@data = main::grabber("$client{'name'} -v");
		$string = awk(\@data,'Version');
		if ($string){
			$string =~ s/[()]|bitchx-//g; 
			@data = split /\s+/, $string;
			$_=lc for @data;
			$client{'version'} = ($data[1] eq 'version') ? $data[2] : $data[1];
		}
	}
	# 'hexchat' => ['',0,'','HexChat',0,0], # special
	# the hexchat author decided to make --version/-v return a gtk dialogue box, lol...
	# so we need to read the actual config file for hexchat. Note that older hexchats
	# used xchat config file, so test first for default, then legacy. Because it's possible
	# for this file to be user edited, doing some extra checks here.
	elsif ($client{'name'} eq 'hexchat') {
		if ( -f '~/.config/hexchat/hexchat.conf' ){
			@data = main::reader('~/.config/hexchat/hexchat.conf','strip');
		}
		elsif ( -f '~/.config/hexchat/xchat.conf' ){
			@data = main::reader('~/.config/hexchat/xchat.conf','strip');
		}
		$client{'version'} = main::awk(\@data,'version',2,'\s*=\s*');
		$client{'name-print'} = 'HexChat';
	}
	# note: see legacy inxi konvi logic if we need to restore any of the legacy code.
	elsif ($client{'name'} eq 'konversation') {
		$client{'konvi'} = ( ! $client{'native'} ) ? 2 : 1;
	}
	elsif ($client{'name'} =~ /quassel/) {
		@data = main::grabber("$client{'name'} -v 2>/dev/null");
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
		my @cmdline = main::get_cmdline();
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
	eval $end if $b_log;
}
sub get_cmdline {
	eval $start if $b_log;
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
	main::log_data("cmdline: @cmdline count: $i") if $b_log;
	eval $end if $b_log;
	return @cmdline;
}
sub perl_python_client {
	eval $start if $b_log;
	return 1 if $client{'version'};
	# this is a hack to try to show konversation if inxi is running but started via /cmd
	# OR via script shortcuts, both cases in fact now
	# main::print_line("konvi: " . scalar grep { $_ =~ /konversation/ } @ps_cmd);
	if ( $b_display && ( scalar grep { $_ =~ /konversation/ } @ps_cmd ) > 0){
		@app = main::program_values('konversation');
		$client{'version'} = main::program_version('konversation',$app[0],$app[1],$app[2]);
		$client{'name'} = 'konversation';
		$client{'name-print'} = $app[3];
		$client{'console-irc'} = $app[4];
	}
	## NOTE: supybot only appears in ps aux using 'SHELL' command; the 'CALL' command
	## gives the user system irc priority, and you don't see supybot listed, so use SHELL
	elsif ( !$b_display && ( scalar grep { $_ =~ /supybot/ } @ps_cmd ) > 0  ){
		@app = main::program_values('supybot');
		$client{'version'} = main::program_version('supybot',$app[0],$app[1],$app[2]);
		if ($client{'version'}){
			if ( ( scalar grep { $_ =~ /gribble/ } @ps_cmd ) > 0){
				$client{'name'} = 'gribble';
				$client{'name-print'} = 'Gribble';
			}
			if ( ( scalar grep { $_ =~ /limnoria/ } @ps_cmd ) > 0){
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
	main::log_data("namep: $client{'name-print'} name: $client{'name'} version: $client{'version'}") if $b_log;
	eval $end if $b_log;
}
## try to infer the use of Konversation >= 1.2, which shows $PPID improperly
## no known method of finding Konvi >= 1.2 as parent process, so we look to see if it is running,
## and all other irc clients are not running. As of 2014-03-25 this isn't used in my cases
sub check_modern_konvi {
	eval $start if $b_log;
	
	return 0 if ! $client{'qdbus'};
	my $b_modern_konvi = 0;
	my $konvi_version = '';
	my $konvi = '';
	my $pid = '';
	my (@temp);
	# main::log_data("name: $client{'name'} :: qdb: $client{'qdbus'} :: version: $client{'version'} :: konvi: $client{'konvi'} :: PPID: $ppid") if $b_log;
	# sabayon uses /usr/share/apps/konversation as path
	if ( -d '/usr/share/kde4/apps/konversation' || -d '/usr/share/apps/konversation' ){
		$pid = main::awk(\@ps_aux,'konversation',2,'\s+');
		main::log_data("pid: $pid") if $b_log;
		$konvi = readlink ("/proc/$pid/exe");
		$konvi =~ s/^.*\///; # basename
		@app = main::program_values('konversation');
		if ($konvi){
			@app = main::program_values('konversation');
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
	qdb: $client{'qdbus'} version: $konvi_version konvi: $konvi PID: $pid") if $b_log;
	main::log_data("b_is_qt4: $b_modern_konvi") if $b_log;
	## for testing this module
# 	my $ppid = getppid();
# 	system('qdbus org.kde.konversation', '/irc', 'say', $client{'dserver'}, $client{'dtarget'}, 
# 	"getpid_dir: $konvi_qt4 verNum: $konvi_version pid: $pid ppid: $ppid" );
	eval $end if $b_log;
	return $b_modern_konvi;
}

sub set_konvi_data {
	eval $start if $b_log;
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
		my @data = main::grabber("$config_tool --path data 2>/dev/null",':');
		main::get_configs(@data);
	}
	eval $end if $b_log;
}
}


### END MODULE CODE ##

### START TEST CODE ##

my $type = 'st';
my $t0 = [gettimeofday];
foreach (0 .. 1){
	if ($type eq 'ob') {
# 		my $ob_start = StartClient->new();
# 		$ob_start->get_client_data();
	}
	# elsif ($ARGV[0] eq 'nc'){
	# 	get_client_data();
	# }
	else {
		StartClient::get_client_data();
	}
}
my $t1 = [gettimeofday];
my $t0_t1 = tv_interval $t0, $t1;
print "type: $type elapsed: $t0_t1\n";

#print "namep: $client{'name-print'} v: $client{'version'}\n";
