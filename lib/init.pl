#!/usr/bin/env perl
## File: init.pl
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
my @paths = qw(/sbin /bin /usr/sbin /usr/bin /usr/X11R6/bin /usr/local/sbin /usr/local/bin);

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

# args: 1 - desktop/app command for --version; 2 - search string; 
# 3 - space print number; 4 - [optional] version arg: -v, version, etc
sub program_version {
	eval $start if $b_log;
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
		open my $ch, '<', \$output or error_handler('open-data',"$cmd", "$!");
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
	eval $end if $b_log;
	return $version_nu;
}
my %show;
$show{'display-data'}  = 1;

### END CODE REQUIRED BY THIS MODULE ##

### START MODULE CODE ##

sub get_init_data {
	eval $start if $b_log;
	my $runlevel = get_runlevel_data();
	my $default = ($extra > 1) ? get_runlevel_default() : '';
	my ($init,$init_version,$rc,$rc_version,$program) = ('','','','','');
	my $comm = ( -e '/proc/1/comm' ) ? (reader('/proc/1/comm'))[0] : '';
	my (@data);
	# this test is pretty solid, if pid 1 is owned by systemd, it is systemd
	# otherwise that is 'init', which covers the rest of the init systems.
	# more data may be needed for other init systems.
	if ($comm && $comm =~ /systemd/ ){
		$init = 'systemd';
		if ( $program = check_program('systemd')){
			$init_version = program_version($program,'^systemd','2','--version');
		}
		if (!$init_version && ($program = check_program('systemctl') ) ){
			$init_version = program_version($program,'^systemd','2','--version');
		}
	}
	else {
		# /sbin/init --version == init (upstart 1.12.1)
		if ($comm =~ /upstart/){
			$init = 'Upstart';
			$init_version = program_version('init', 'upstart', '3','--version');
		}
		# epoch version == Epoch Init System 1.0.1 "Sage"
		elsif ($comm =~ /epoch/){
			$init = 'Epoch';
			$init_version = program_version('epoch', '^Epoch', '4','version');
		}
		# missing data: note, runit can install as a dependency without being the 
		# init system: http://smarden.org/runit/sv.8.html
		# NOTE: the proc test won't work on bsds, so if runit is used on bsds we 
		# will need more data
		elsif ($comm =~ /runit/){
			$init = 'runit';
		}
		elsif (check_program('launchctl')){
			$init = 'launchd';
		}
		elsif ( -f '/etc/inittab' ){
			$init = 'SysVinit';
			if (check_program('strings')){
				@data = data_dumper('strings /sbin/init');
				$init_version = awk(\@data,'version\s+[0-9]');
				$init_version = get_piece($init_version,2) if $init_version;
			}
		}
		elsif ( -f '/etc/ttys' ){
			$init = 'init (BSD)';
		}
		if ( grep { /openrc/ } </run/*> ){
			$rc = 'OpenRC';
			# /sbin/openrc --version == openrc (OpenRC) 0.13
			if ($program = check_program('openrc')){
				$rc_version = program_version($program, '^openrc', '3','--version');
			}
			# /sbin/rc --version == rc (OpenRC) 0.11.8 (Gentoo Linux)
			elsif ($program = check_program('rc')){
				$rc_version = program_version($program, '^rc', '3','--version');
			}
			if ( -e '/run/openrc/softlevel' ){
				$runlevel = (reader('/run/openrc/softlevel'))[0];
			}
			elsif ( -e '/var/run/openrc/softlevel'){
				$runlevel = (reader('/var/run/openrc/softlevel'))[0];
			}
			elsif ( $program = check_program('rc-status')){
				$runlevel = (grabber("$program -r 2>/dev/null"))[0];
			}
		}
	}
	my %init = (
	'init-type' => $init,
	'init-version' => $init_version,
	'rc-type' => $rc,
	'rc-version' => $rc_version,
	'runlevel' => $runlevel,
	'default' => $default,
	);
	eval $end if $b_log;
	return %init;
}

# # check? /var/run/nologin for bsds?
sub get_runlevel_data {
	eval $start if $b_log;
	my $runlevel = '';
	if ( my $program = check_program('runlevel')){
		$runlevel = (grabber($program))[0];
		$runlevel =~ s/[^\d]//g;
		#print_line($runlevel . ";;");
	}
	eval $end if $b_log;
	return $runlevel;
}
# note: it appears that at least as of 2014-01-13, /etc/inittab is going 
# to be used for default runlevel in upstart/sysvinit. systemd default is 
# not always set so check to see if it's linked.
sub get_runlevel_default {
	eval $start if $b_log;
	my @data;
	my $default = '';
	my $b_systemd = 0;
	my $inittab = '/etc/inittab';
	my $systemd = '/etc/systemd/system/default.target';
	my $upstart = '/etc/init/rc-sysinit.conf';
	# note: systemd systems do not necessarily have this link created
	if ( -e $systemd){
		$default = readlink($systemd);
		$default =~ s/.*\/// if $default; 
		$b_systemd = 1;
	}
	# http://askubuntu.com/questions/86483/how-can-i-see-or-change-default-run-level
	# note that technically default can be changed at boot but for inxi purposes 
	# that does not matter, we just want to know the system default
	elsif ( -e $upstart){
		# env DEFAULT_RUNLEVEL=2
		@data = reader($upstart);
		$default = awk(\@data,'^env\s+DEFAULT_RUNLEVEL',2,'=');
	}
	# handle weird cases where null but inittab exists
	if (!$default && -e $inittab ){
		@data = reader($inittab);
		$default = awk(\@data,'^id.*initdefault',2,':');
	}
	eval $end if $b_log;
	return $default;
}

### END MODULE CODE ##

### START TEST CODE ##

print join( ', ', get_runlevel_data()), "\n";

