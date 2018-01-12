#!/usr/bin/env perl
## File: desktop.pl
## Version: 1.5
## Date 2018-01-12
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
my $display;
my $display_opt = '';
my $extra = 3;
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

my @ps_cmd = qx(ps aux);

# returns array of:
# 0 - match string; 1 - search number; 2 - version string; 3 - Print name
# 4 - console 0/1; 5 - 0/1 exit version loop at first iteration
# arg: 1 - program lower case name
sub program_values {
	my ($app) = @_;
	my (@client_data);
	my %data = (
	# clients
	'bitchx' => ['bitchx',2,'','BitchX',1,0],# special
	'finch' => ['finch',2,'-v','Finch',1,1],
	'gaim' => ['[0-9.]+',2,'-v','Gaim',0,1],
	'ircii' => ['[0-9.]+',3,'-v','ircII',1,1],
	'irssi' => ['irssi',2,'-v','Irssi',1,1],
	'irssi-text' => ['irssi',2,'-v','Irssi',1,1],
	'konversation' => ['konversation',2,'-v','Konversation',0,0],
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
	# desktops 
	'afterstep' => ['^afterstep',3,'--version','AfterStep',0,1],
	'awesome' => ['^awesome',2,'--version','Awesome',0,1],
	'budgie' => ['^budgie-desktop',2,'--version','Budgie',0,1],
	'cinnamon' => ['^cinnamon',2,'--version','^Cinnamon',0,1],
	'dwm' => ['^dwm',1,'-v','dwm',0,1],
	'fluxbox' => ['^fluxbox',2,'--version','Fluxbox',0,1],
	'fvwm' => ['^fvwm',2,'--version','FVWM',0,1],
	# command: fvwm
	'fvwm-crystal' => ['^fvwm',2,'--version','FVWM-Crystal',0,1], 
	'gnome-about' => ['gnome',3,'--version','^Gnome',0,1],
	'gnome-shell' => ['gnome',3,'--version','^Gnome',0,1],
	'herbstluftwm' => ['^herbstluftwm',-1,'--version','herbstluftwm',0,1],
	'jwm' => ['^jwm',2,'--version','JWM',0,1],
	'i3' => ['^i3',2,'--version','i3',0,1],
	'icewm' => ['^icewm',2,'--version','IceWM',0,1],
	'kded' => ['^KDE:',2,'--version','KDE',0,1],
	'kded3' => ['^KDE Development Platform:',4,'--version','KDE',0,1],
	'kded4' => ['^KDE Development Platform:',4,'--version','KDE',0,1],
	'kf5-config' => ['^KDE Frameworks:',2,'--version','KDE Plasma',0,1],
	'kf6-config' => ['^KDE Frameworks:',2,'--version','KDE Plasma',0,1],
	# command: lxqt-about
	'lxqt' => ['^lxqt-about',2,'--version','LXQT',0,1],
	'mate' => ['^MATE[[:space:]]DESKTOP',-1,'--version','MATE',0,1],
	'openbox' => ['^openboxt',2,'--version','Openbox',0,1],
	'pekwm' => ['^pekwm',3,'--version','pekwm',0,1],
	'plasmashell' => ['^plasmashell',2,'--version','KDE Plasma',0,1],
	'qtdiag' => ['^qt',2,'--version','Qt',0,1],
	'sawfish' => ['^sawfish',3,'--version','Sawfish',0,1],
	'scrotwm' => ['^welcome.*scrotwm',4,'-v','Scrotwm',0,1],
	'spectrwm' => ['^spectrwm.*welcome.*spectrwm',5,'-v','Spectrwm',0,1],
	'unity' => ['^unity',2,'--version','Unity',0,1],
	'wm2' => ['^wm2',-1,'--version','WM2',0,1],
	'wmaker' => ['^Window[[:space:]]*Maker',-1,'--version','WindowMaker',0,1],
	'wmii' => ['^wmii',1,'--version','wmii',0,1], # note: in debian, wmii is wmii3
	'wmii2' => ['^wmii2',1,'--version','wmii2',0,1],
	'xfce4-panel' => ['^xfce4-panel',2,'--version','Xfce',0,1],
	'xfce5-panel' => ['^xfce5-panel',2,'--version','Xfce',0,1],
	'xfdesktop' => ['xfdesktop[[:space:]]version',5,'--version','Xfce',0,1],
	# command: xfdesktop
	'xfdesktop-toolkit' => ['Built[[:space:]]with[[:space:]]GTK',4,'--version','Gtk',0,1],
	
	# shells
	'bash' => ['^GNU[[:space:]]bash,[[:space:]]version',4,'--version','Bash',1,0],
	'csh' => ['^tcsh',2,'--version','csh',1,0],
	'dash' => ['dash',3,'--version','Dash',1,0], # no version, uses dpkg query, sigh
	'ksh' => ['version',5,'-v','csh',1,0], # ksh is too weird to try to handle with version
	'tcsh' => ['^tcsh',2,'--version','tcsh',1,0],
	'zsh' => ['^zsh',2,'--version','zsh',1,0],
	# tools
	'clang' => ['clang',4,'--version','Clang',1,0],
	'gcc' => ['^gcc',3,'--version','GCC',1,0],
	'gcc-apple' => ['Apple[[:space:]]LLVM',2,'--version','csh',1,0],
	);
	if ( defined $data{$app} ){
		my $ref = $data{$app};
		@client_data = @$ref;
	}
	#my $debug = main::Dumper \@client_data;
	# main::log_data("Client Data: " . main::Dumper \@client_data);
	return @client_data;
}
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
	$num-- if $num > 0;
	
	# dump these once the dm stuff is done, we'll pass this data
	# we're not trying to get ksh any more, it's too difficult
	#if ( $app =~ /^ksh/) {
	#	$version = '-v';
	#}
	# konvi in particular doesn't like using $ENV{'PATH'} as set, so we need
	# to always assign the full path if it hasn't already been done
	if ( $app !~ /^\//){
		$app = check_program($app);
	}
	# note, some wm/apps send version info to stderr instead of stdout
	if ( $app =~ /\/(dwm|ksh|kvirc|scrotwm)$/ ) {
		$cmd = "$app $version 2>&1";
	}
# 	elsif ( $app eq 'csh' ){
# 		$app = 'tcsh';
# 	}
	# quick debian/buntu hack until I find a universal way to get version for these
	elsif ( $app eq 'dash' ){
		$cmd = "dpkg -l $app 2>/dev/null";
	}
	else {
		$cmd = "$app $version 2>/dev/null";
	}
	log_data("version: $version num: $num search: $search command: $cmd") if $b_log;
	$output = qx($cmd);
	# print "$cmd : $output\n";
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
	log_data("Program version: $version_nu") if $b_log;
	eval $end if $b_log;
	return $version_nu;
}

### END CODE REQUIRED BY THIS MODULE ##

### START MODULE CODE ##

# Get DesktopEnvironment
## returns array:
# 0 - desktop name
# 1 - version
# 2 - toolkit
# 3 - toolkit version
# 4 - info extra desktop data
{
package DesktopEnvironment;
my ($b_xprop,$kde_session_version,$xdg_desktop,@desktop,@data,@xprop);
sub get {
	
	# NOTE $XDG_CURRENT_DESKTOP envvar is not reliable, but it shows certain desktops better.
	# most desktops are not using it as of 2014-01-13 (KDE, UNITY, LXDE. Not Gnome)
	$xdg_desktop = ( $ENV{'XDG_CURRENT_DESKTOP'} ) ? $ENV{'XDG_CURRENT_DESKTOP'} : '';
	$kde_session_version = ($ENV{'KDE_SESSION_VERSION'}) ? $ENV{'KDE_SESSION_VERSION'} : '';
	get_kde_data();
	
	if (!@desktop){
		get_env_de_data();
	}
	if (!@desktop){
		get_env_xprop_de_data();
	}
	if (!@desktop && $b_xprop ){
		get_xprop_de_data();
	}
	if (!@desktop){
		get_ps_de_data();
	}
	if ($extra > 2 && @desktop){
		set_info_data();
	}
	main::log_data('desktop data: ' . join '; ', @desktop) if $b_log;
	return @desktop;
}
sub get_kde_data {
	eval $start if $b_log;
	my ($program,@version_data,@version_data2);
	my $kde_full_session = ($ENV{'KDE_FULL_SESSION'}) ? $ENV{'KDE_FULL_SESSION'} : '';
	return 1 if ($xdg_desktop ne 'KDE' && !$kde_session_version && $kde_full_session ne 'true' );
	# works on 4, assume 5 will id the same, why not, no need to update in future
	# KDE_SESSION_VERSION is the integer version of the desktop
	# NOTE: as of plasma 5, the tool: about-distro MAY be available, that will show
	# actual desktop data, so once that's in debian/ubuntu, if it gets in, add that test
	if ($xdg_desktop eq 'KDE' || $kde_session_version ){
		if ($kde_session_version <= 4){
			@data = main::program_values("kded$kde_session_version");
			$desktop[0] = $data[3];
			$desktop[1] = main::program_version("kded$kde_session_version",$data[0],$data[1],$data[2],$data[5]);
		}
		else {
			# NOTE: this command string is almost certain to change, and break, with next 
			# major plasma desktop, ie, 6. 
			# qdbus org.kde.plasmashell /MainApplication org.qtproject.Qt.QCoreApplication.applicationVersion
			# Qt: 5.4.2
			# KDE Frameworks: 5.11.0
			# kf5-config: 1.0
			# for QT, and Frameworks if we use it
			if ($program = main::check_program("kded$kde_session_version")){
				@version_data = main::data_grabber("$program --version 2>/dev/null");
			}
			if ($program = main::check_program("plasmashell")){
				@version_data2 = main::data_grabber("$program --version 2>/dev/null");
				$desktop[1] = main::awk(\@version_data2,'^plasmashell',-1,'\s+');
			}
			$desktop[0] = 'KDE Plasma';
		}
		if (!$desktop[1]){
			$desktop[1] = $kde_session_version;
		}
		print Data::Dumper::Dumper \@version_data;
		if ($extra > 0 && @version_data){
			$desktop[2] = 'Qt';
			$desktop[3] = main::awk(\@version_data,'^Qt:', 2,'\s+');
		}
	}
	# KDE_FULL_SESSION property is only available since KDE 3.5.5.
	elsif ($kde_full_session eq 'true'){
		@version_data = main::data_grabber("kded --version 2>/dev/null");
		$desktop[0] = 'KDE';
		$desktop[1] = main::awk(\@version_data,'^KDE:',2,'\s+');
		if (!$desktop[1]){
			$desktop[1] = '3.5';
		}
		if ($extra > 0){
			$desktop[3] = main::awk(\@version_data,'^Qt:',2,'\s+');
		}
	}
	eval $end if $b_log;
}
sub get_env_de_data {
	eval $start if $b_log;
	my ($program,@version_data);
	
	if ($xdg_desktop eq 'Unity'){
		@data = main::program_values('unity');
		$desktop[0] = $data[3];
		$desktop[0] ||= 'Unity';
		$desktop[1] = main::program_version('cinnamon',$data[0],$data[1],$data[2],$data[5]);
		set_gtk_data() if $extra > 0;
	}
	elsif ( $xdg_desktop =~ /Budgie/i ){
		@data = main::program_values('budgie');
		$desktop[0] = $data[3];
		$desktop[1] = main::program_version('budgie-desktop',$data[0],$data[1],$data[2],$data[5]);
		set_gtk_data() if $extra > 0;
	}
	elsif ( $xdg_desktop eq 'LXQT' ){
		@data = main::program_values('lxqt');
		$desktop[0] = $data[3];
		$desktop[0] ||= 'LXQT';
		$desktop[1] = main::program_version('lxqt-about',$data[0],$data[1],$data[2],$data[5]);
		if ( $extra > 0 ){
			if ($program = main::check_program("kded$kde_session_version") ){
				@version_data = main::data_grabber("$program --version 2>/dev/null");
				$desktop[2] = 'Qt';
				$desktop[3] = main::awk(\@version_data,'^Qt:',2);
			}
			elsif ($program = main::check_program("qtdiag") ){
				@data = main::program_values('qtdiag');
				$desktop[3] = main::program_version($program,$data[0],$data[1],$data[2],$data[5]);
				$desktop[2] = $data[3];
			}
		}
	}
	# note, X-Cinnamon value strikes me as highly likely to change, so just 
	# search for the last part
	elsif ( $xdg_desktop =~ /Cinnamon/i ){
		@data = main::program_values('cinnamon');
		$desktop[0] = $data[3];
		$desktop[1] = main::program_version('cinnamon',$data[0],$data[1],$data[2],$data[5]);
		set_gtk_data() if $extra > 0;
	}
	eval $end if $b_log;
}
sub get_env_xprop_de_data {
	eval $start if $b_log;
	my ($program,@version_data);
	set_xprop();
	# note that cinnamon split from gnome, and and can now be id'ed via xprop,
	# but it will still trigger the next gnome true case, so this needs to go 
	# before gnome test eventually this needs to be better organized so all the 
	# xprop tests are in the same section, but this is good enough for now.
	if ($b_xprop && main::awk(\@xprop,'_muffin' )){
		@data = main::program_values('cinnamon');
		$desktop[0] = $data[3];
		$desktop[1] = main::program_version('cinnamon',$data[0],$data[1],$data[2],$data[5]);
		set_gtk_data() if $extra > 0;
		$desktop[0] ||= 'Cinnamon';
	}
	elsif ($xdg_desktop eq 'MATE' || $b_xprop && main::awk(\@xprop,'_marco')){
		@data = main::program_values('mate');
		$desktop[0] = $data[3];
		$desktop[1] = main::program_version('mate-about',$data[0],$data[1],$data[2],$data[5]);
		set_gtk_data() if $extra > 0;
		$desktop[0] ||= 'MATE';
	}
	# note, GNOME_DESKTOP_SESSION_ID is deprecated so we'll see how that works out
	# https://bugzilla.gnome.org/show_bug.cgi?id=542880
	elsif ($xdg_desktop eq 'GNOME' || $ENV{'GNOME_DESKTOP_SESSION_ID'}){
		if ($program = main::check_program('gnome-about') ) {
			@data = main::program_values('gnome-about');
			$desktop[1] = main::program_version('gnome-about',$data[0],$data[1],$data[2],$data[5]);
		}
		elsif ($program = main::check_program('gnome-shell') ) {
			@data = main::program_values('gnome-shell');
			$desktop[1] = main::program_version('gnome-shell',$data[0],$data[1],$data[2],$data[5]);
		}
		set_gtk_data() if $extra > 0;
		$desktop[0] = ($data[3])?$data[3] :'Gnome';
	}
	eval $end if $b_log;
}
sub get_xprop_de_data {
	eval $start if $b_log;
	my ($program,@version_data,$version);
	#print join "\n", @xprop, "\n";
	# String: "This is xfdesktop version 4.2.12"
	# alternate: xfce4-about --version > xfce4-about 4.10.0 (Xfce 4.10)
	if (main::awk(\@xprop,'xfce' )){
		if (grep {/\"xfce4\"/} @xprop){
			$version = '4';
		}
		elsif (grep {/\"xfce5\"/} @xprop){
			$version = '5';
		}
		else {
			$version = '4';
		}
		@data = main::program_values('xfdesktop');
		$desktop[0] = $data[3];
		# out of x, this error goes to stderr, so it's an empty result
		$desktop[1] = main::program_version('xfdesktop',$data[0],$data[1],$data[2],$data[5]);
		if ( !$desktop[1] ){
			@data = main::program_values("xfce${version}-panel");
			# print Data::Dumper::Dumper \@data;
			# this returns an error message to stdout in x, which breaks the version
			$desktop[1] = main::program_version("xfce${version}-panel",$data[0],$data[1],$data[2],$data[5]);
			# out of x this kicks out an error: xfce4-panel: Cannot open display
			$desktop[1] = '' if $desktop[1] !~ /[0-9]\./; 
		}
		$desktop[0] ||= 'Xfce';
		$desktop[1] ||= 4;
		if ($extra > 0){
			@data = main::program_values('xfdesktop-toolkit');
			$desktop[3] = main::program_version('xfdesktop',$data[0],$data[1],$data[2],$data[5]);
			$desktop[2] = $data[3];
		}
		
	}
	elsif ( main::awk(\@xprop,'blackbox_pid' )){
		if (grep {/fluxbox/} @ps_cmd){
			@data = main::program_values('fluxbox');
			$desktop[0] = $data[3];
			$desktop[1] = main::program_version('fluxbox',$data[0],$data[1],$data[2],$data[5]);
		}
		else {
			$desktop[0] = 'Blackbox';
		}
	}
	elsif ( main::awk(\@xprop,'openbox_pid' )){
		# note: openbox-lxde --version may be present, but returns openbox data
		@data = main::program_values('openbox');
		$desktop[1] = main::program_version('openbox',$data[0],$data[1],$data[2],$data[5]);
		if ($xdg_desktop eq 'LXDE' || main::awk(\@ps_cmd, 'lxsession')){
			$desktop[1] = "(Openbox $desktop[1])" if $desktop[1];
			$desktop[0] = 'LXDE';
		}
		elsif ($xdg_desktop eq 'Razor' || $xdg_desktop eq 'LXQt' || main::awk(\@ps_cmd, 'razor-desktop|lxqt-session')) {
			if (main::awk(\@ps_cmd,'lxqt-session' )){
				$desktop[0] = 'LXQt';
			}
			elsif (main::awk(\@ps_cmd, 'razor-desktop')){
				$desktop[0] = 'Razor-Qt';
			}
			else {
				$desktop[0] = 'LX-Qt-Variant';
			}
			$desktop[1] = "(Openbox $desktop[1])" if $desktop[1];
		}
		else {
			$desktop[0] = 'Openbox';
		}
	}
	elsif (main::awk(\@xprop,'icewm' )){
		@data = main::program_values('icewm');
		$desktop[0] = $data[3];
		$desktop[1] = main::program_version('icewm',$data[0],$data[1],$data[2],$data[5]);
	}
	elsif (main::awk(\@xprop,'enlightenment' )){
		$desktop[0] = 'Enlightenment';
		# no -v or --version but version is in xprop -root
		# ENLIGHTENMENT_VERSION(STRING) = "Enlightenment 0.16.999.49898"
		$desktop[1] = main::awk(\@xprop,'enlightenment_version',2,'\s+=\s+' );
		$desktop[1] = (split /"/, $desktop[1])[1] if $desktop[1];
		$desktop[1] = (split /\s+/, $desktop[1])[1] if $desktop[1];
	}
	elsif (main::awk(\@xprop,'^i3_' )){
		@data = main::program_values('i3');
		$desktop[0] = $data[3];
		$desktop[1] = main::program_version('i3',$data[0],$data[1],$data[2],$data[5]);
	}
	elsif (main::awk(\@xprop,'^windowmaker' )){
		@data = main::program_values('wmaker');
		$desktop[0] = $data[3];
		$desktop[1] = main::program_version('wmaker',$data[0],$data[1],$data[2],$data[5]);
	}
	elsif (main::awk(\@xprop,'^_wm2' )){
		@data = main::program_values('wm2');
		$desktop[0] = $data[3];
		$desktop[1] = main::program_version('wm2',$data[0],$data[1],$data[2],$data[5]);
	}
	elsif (main::awk(\@xprop,'herbstluftwm' )){
		@data = main::program_values('herbstluftwm');
		$desktop[0] = $data[3];
		$desktop[1] = main::program_version('herbstluftwm',$data[0],$data[1],$data[2],$data[5]);
	}
	# need to check starts line because it's so short
	eval $end if $b_log;
}
sub get_ps_de_data {
	eval $start if $b_log;
	my ($program,@version_data);
	if ( main::awk(\@ps_cmd,'fvwm-crystal' )){
		@data = main::program_values('fvwm-crystal');
		$desktop[0] = $data[3];
		$desktop[1] = main::program_version('fvwm',$data[0],$data[1],$data[2],$data[5]);
	}
	elsif (main::awk(\@ps_cmd,'fvwm' )){
		@data = main::program_values('fvwm');
		$desktop[0] = $data[3];
		$desktop[1] = main::program_version('fvwm',$data[0],$data[1],$data[2],$data[5]);
	}
	elsif (main::awk(\@ps_cmd,'pekwm' )){
		@data = main::program_values('pekwm');
		$desktop[0] = $data[3];
		$desktop[1] = main::program_version('pekwm',$data[0],$data[1],$data[2],$data[5]);
	}
	elsif (main::awk(\@ps_cmd,'awesome' )){
		@data = main::program_values('awesome');
		$desktop[0] = $data[3];
		$desktop[1] = main::program_version('awesome',$data[0],$data[1],$data[2],$data[5]);
	}
	elsif (main::awk(\@ps_cmd,'scrotwm' )){
		@data = main::program_values('scrotwm');
		$desktop[0] = $data[3];
		$desktop[1] = main::program_version('scrotwm',$data[0],$data[1],$data[2],$data[5]);
	}
	elsif (main::awk(\@ps_cmd,'spectrwm' )){
		@data = main::program_values('spectrwm');
		$desktop[0] = $data[3];
		$desktop[1] = main::program_version('spectrwm',$data[0],$data[1],$data[2],$data[5]);
	}
	elsif (main::awk(\@ps_cmd,'(\s|\/)twm' )){
		# no version
		$desktop[0] = 'Twm';
	}
	elsif (main::awk(\@ps_cmd,'(\s|\/)dwm' )){
		@data = main::program_values('dwm');
		$desktop[0] = $data[3];
		$desktop[1] = main::program_version('dwm',$data[0],$data[1],$data[2],$data[5]);
	}
	elsif (main::awk(\@ps_cmd,'wmii2' )){
		@data = main::program_values('wmii2');
		$desktop[0] = $data[3];
		$desktop[1] = main::program_version('wmii2',$data[0],$data[1],$data[2],$data[5]);
	}
	elsif (main::awk(\@ps_cmd,'wmii' )){
		@data = main::program_values('wmii');
		$desktop[0] = $data[3];
		$desktop[1] = main::program_version('wmii',$data[0],$data[1],$data[2],$data[5]);
	}
	elsif (main::awk(\@ps_cmd,'(\s|\/)jwm' )){
		@data = main::program_values('jwm');
		$desktop[0] = $data[3];
		$desktop[1] = main::program_version('jwm',$data[0],$data[1],$data[2],$data[5]);
	}
	elsif (main::awk(\@ps_cmd,'sawfish' )){
		@data = main::program_values('sawfish');
		$desktop[0] = $data[3];
		$desktop[1] = main::program_version('sawfish',$data[0],$data[1],$data[2],$data[5]);
	}
	elsif ( grep {/afterstep/} @ps_cmd){
		@data = main::program_values('afterstep');
		$desktop[0] = $data[3];
		$desktop[1] = main::program_version('afterstep',$data[0],$data[1],$data[2],$data[5]);
	}
	eval $end if $b_log;
}

sub set_gtk_data {
	eval $start if $b_log;
	my ($version,$program,@data);
	# this is a hack, and has to be changed with every toolkit version change, and 
	# only dev systems 	# have this installed, but it's a cross distro command try it.
	if ($program = main::check_program('pkg-config')){
		@data = main::data_grabber("$program --modversion gtk+-4.0 2>/dev/null");
		$version = main::awk(\@data,'\S');
		# note: opensuse gets null output here, we need the command to get version and output sample
		if ( !$version ){
			@data = main::data_grabber("$program --modversion gtk+-3.0 2>/dev/null");
			$version = main::awk(\@data,'\S');
		}
		if ( !$version ){
			@data = main::data_grabber("$program --modversion gtk+-2.0 2>/dev/null");
			$version = main::awk(\@data,'\S');
		}
	}
	# now let's go to more specific version tests, this will never cover everything and that's fine.
	if (!$version){
		# we'll try some known package managers next. dpkg will handle a lot of distros 
		# this is the most likely order as of: 2014-01-13. Not going to try to support all 
		# package managers too much work, just the very biggest ones.
		if ($program = main::check_program('dpkg')){
			@data = main::data_grabber("$program -s libgtk-3-0 2>/dev/null");
			$version = main::awk(\@data,'^\s*Version',2,'\s+');
			# just guessing on gkt 4 package name
			if (!$version){
				@data = main::data_grabber("$program -s libgtk-4-0 2>/dev/null");
				$version = main::awk(\@data,'^\s*Version',2,'\s+');
			}
			if (!$version){
				@data = main::data_grabber("$program -s libgtk2.0-0 2>/dev/null");
				$version = main::awk(\@data,'^\s*Version',2,'\s+');
			}
		}
		elsif ($program = main::check_program('pacman')){
			@data = main::data_grabber("$program -Qi gtk3 2>/dev/null");
			$version = main::awk(\@data,'^\s*Version',2,'\s*:\s*');
			# just guessing on gkt 4 package name
			if (!$version){
				@data = main::data_grabber("$program -Qi gtk4 2>/dev/null");
				$version = main::awk(\@data,'^\s*Version',2,'\s*:\s*');
			}
			if (!$version){
				@data = main::data_grabber("$program -Qi gtk2 2>/dev/null");
				$version = main::awk(\@data,'^\s*Version',2,'\s*:\s*');
			}
		}
		elsif ($program = main::check_program('rpm')){
			@data = main::data_grabber("$program -qi libgtk-3-0 2>/dev/null");
			$version = main::awk(\@data,'^\s*Version',2,'\s*:\s*');
			# just guessing on gkt 4 package name
			if (!$version){
				@data = main::data_grabber("$program -qi libgtk-4-0 2>/dev/null");
				$version = main::awk(\@data,'^\s*Version',2,'\s*:\s*');
			}
			if (!$version){
				@data = main::data_grabber("$program -qi libgtk-3-0 2>/dev/null");
				$version = main::awk(\@data,'^\s*Version',2,'\s*:\s*');
			}
		}
	}
	$desktop[2] = 'Gtk';
	eval $end if $b_log;
}
sub set_info_data {
	eval $start if $b_log;
	my (@data,@info,$item);
	if (@data = grep {/gnome-shell|gnome-panel|kicker|lxpanel|mate-panel|plasma-desktop|plasma-netbook|xfce4-panel/} @ps_cmd ) {
		# only one entry per type, can be multiple
		foreach $item (@data){
			if (! main::awk(\@info, "$item")){
				$item = main::trimmer($item);
				push @info, (split /\s+/, $item)[0];
			}
		}
	}
	$desktop[4] = join (',', @info) if @info;
	eval $end if $b_log;
}

sub set_xprop {
	eval $start if $b_log;
	if (my $program = main::check_program('xprop')){
		@xprop = grep {/^\S/} main::data_grabber("xprop -root $display_opt 2>/dev/null");
		$_=lc for @xprop;
		$b_xprop = 1 if scalar @xprop > 5;
	}
	eval $end if $b_log;
}

}

sub get_display_manager {
	eval $start if $b_log;
	my (@data,@found,$temp,$working);
	# ldm - LTSP display manager. Note that sddm does not appear to have a .pid 
	# extension in Arch note: to avoid positives with directories, test for -f 
	# explicitly, not -e
	my @dms = qw(entranced.pid gdm.pid gdm3.pid kdm.pid ldm.pid 
	lightdm.pid lxdm.pid mdm.pid nodm.pid sddm.pid sddm slim.lock 
	tint2.pid wdm.pid xdm.pid);
	# this is the only one I know of so far that has --version
	# lightdm outputs to stderr, so it has to be redirected
	my @dms_version = qw(lightdm);
	foreach my $id (@dms){
		# note: ${dm_id%.*}/$dm_id will create a dir name out of the dm id, then 
		# test if pid is in that note: sddm, in an effort to be unique and special, 
		# do not use a pid/lock file, but rather a random string inside a directory 
		# called /run/sddm/ so assuming the existence of the pid inside a directory named
		# from the dm. Hopefully this change will not have negative results.
		$working = $id;
		$working =~ s/\.\S+$//;
		# note: there's always been an issue with duplicated dm's in inxi, this should now correct it
		if ( ( -f "/run/$id" || -d "/run/$working" || -f "/var/run/$id" ) && ! grep {/$working/} @found ){
			if ($extra > 2 && awk( \@dms_version, $working) ){
				@data = main::data_grabber("$working --version 2>&1");
				$temp = awk(\@data,'\S',2,'\s+');
				$working .= ' ' . $temp if $temp;
			}
			push @found, $working;
		}
	}
	if (!@found && grep {/\/usr.*\/x/ && !/\/xprt/} @ps_cmd){
		if (awk (\@ps_cmd, 'startx') ){
			$found[0] = 'startx';
		}
	}
	# might add this in, but the rate of new dm's makes it more likely it's an 
	# unknown dm, so we'll keep output to N/A
	log_data('display manager: ' . join ',', @dms) if $b_log;
	eval $end if $b_log;
	return join ',', @found if @found;
}

### END MODULE CODE ##

### START TEST CODE ##

my @desktop = DesktopEnvironment::get();
print Dumper \@desktop;

my $dm = get_display_manager();
print Dumper $dm;

