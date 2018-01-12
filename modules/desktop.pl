#!/usr/bin/env perl
## File: desktop.pl
## Version: 1.3
## Date 2018-01-11
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


sub get_display_manager {
	eval $start if $b_log;
	my (@found,$working,$temp);
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
			if ($extra > 2 && grep {/$working/} @dms_version ){
				$temp = (split /\s+/, (main::data_grabber("$working --version 2>&1") )[0])[1];
				$working .= ' ' . $temp if $temp;
			}
			push @found, $working;
		}
	}
	if (!@found && grep {/\/usr.*\/x/ && !/\/xprt/} @ps_cmd){
		if (grep {/startx/} @ps_cmd){
			$found[0] = 'startx';
		}
	}
	# might add this in, but the rate of new dm's makes it more likely it's an 
	# unknown dm, so we'll keep output to N/A
	log_data('display manager: ' . join ',', @dms) if $b_log;
	eval $end if $b_log;
	return join ',', @found if @found;
}

## Get DistroData
{
package DistroData;
my ($distro);
sub get {
	if ($bsd_type){
		get_bsd_os();
	}
	else {
		get_linux_distro();
	}
	return $distro;
}

sub get_bsd_os {
	eval $start if $b_log;
	if ($bsd_type eq 'darwin'){
		my $file = '/System/Library/CoreServices/SystemVersion.plist';
		if (-f $file){
			my @data = grep {/(ProductName|ProductVersion)/} reader($file);
			@data = grep {/<string>/} @data;
			@data = map {s/<[\/]?string>//g; } @data;
			$distro = join (' ', @data);
		}
	}
	else {
		my @uname = POSIX::uname();
		$distro = "$uname[0] $uname[2]";
	}
	
	eval $end if $b_log;
	return $distro;
}

sub get_linux_distro {
	eval $start if $b_log;
	my $distro_file = '';
	my (@working,$b_osr);
	my @derived = qw(antix-version aptosid-version kanotix-version knoppix-version 
	mandrake-release mx-version pardus-release porteus-version sabayon-release 
	siduction-version sidux-version slitaz-release solusos-release turbolinux-release 
	zenwalk-version);
	my $derived_s = join "|", @derived;
	my @primary = qw(arch-release gentoo-release redhat-release slackware-version 
	SuSE-release);
	my $primary_s = join "|", @primary;
	my $exclude_s = 'debian_version|devuan_version|ubuntu_version';
	my $lsb_good_s = 'mandrake-release|mandriva-release|mandrakelinux-release';
	my $os_release_good_s = 'arch-release|SuSE-release';
	# note: always exceptions, so wild card after release/version: 
	# /etc/lsb-release-crunchbang
	# wait to handle since crunchbang file is one of the few in the world that 
	# uses this method
	my @distro_files = </etc/*[-_]{[rR]elease,[vV]ersion}*>;
	my $distro_files_s = join "|", @distro_files;
	my $lsb_release = '/etc/lsb-release';
	my $b_lsb = ( -f $lsb_release ) ? 1 : 0;
	my $issue = '/etc/issue';
	my $os_release = '/etc/os-release';
	my $b_os_release = ( -f $os_release ) ? 1 : 0;
	main::log_data( "distro files: " . join "; ",@distro_files);
	if ( $#distro_files == 1 ){
		$distro_file = $distro_files[0];
	}
	else {
		@working = (@derived,@primary);
		foreach my $file (@working){
			if ( "/etc/$file" =~ /($distro_files_s)$/){
				# Now lets see if the distro file is in the known-good working-lsb-list
				# if so, use lsb-release, if not, then just use the found file
				# this is for only those distro's with self named release/version files
				# because Mint does not use such, it must be done as below 
				## this if statement requires the spaces and * as it is, else it won't work
				if ($b_lsb && $file =~ /$lsb_good_s/){
					$distro_file = $lsb_release;
				}
				elsif ($b_os_release && $file =~ /($os_release_good_s)$/){
					$distro_file = $os_release;
				}
				else {
					$distro_file = "/etc/$file";
				}
				last;
			}
		}
		main::log_data("distro_file: $distro_file");
	}
	
	# first test for the legacy antiX distro id file
	if ( -f '/etc/antiX'){
		@working = main::clean_characters( grep { /antix.*\.iso/} main::reader('/etc/antiX') );
		$distro = $working[0];
	}
	# this handles case where only one release/version file was found, and it's lsb-release. 
	# This would never apply for ubuntu or debian, which will filter down to the following 
	# conditions. In general if there's a specific distro release file available, that's to 
	# be preferred, but this is a good backup.
	elsif ($distro_file && $b_lsb && ($distro_file =~ /\/etc\/($lsb_good_s)$/ || $distro_file eq $lsb_release) ){
		$distro = get_lsb_release();
	}
	elsif ($distro_file eq $os_release){
		$distro = get_os_release();
		$b_osr = 1;
	}
	# if distro id file was found and it's not in the exluded primary distro file list, read it
	elsif ( $distro_file && -s $distro_file && $distro_file !~ /\/etc\/($exclude_s)$/){
		# new opensuse uses os-release, but older ones may have a similar syntax, so just use 
		# the first line
		if ($distro_file eq '/etc/SuSE-release'){
			# leaving off extra data since all new suse have it, in os-release, this file has 
			# line breaks, like os-release  but in case we  want it, it's: 
			# CODENAME = Mantis  | VERSION = 12.2 
			# for now, just take first occurrence, which should be the first line, which does 
			# not use a variable type format
			$distro = (main::clean_characters( grep { /suse/i } main::reader($distro_file)))[0];
		}
		else {
			$distro = (main::reader($distro_file))[0];
		}
	}
	# otherwise try  the default debian/ubuntu /etc/issue file
	elsif (-f $issue){
		@working = main::reader($issue);
		my $b_mint = scalar (grep {/mint/i} @working); 
		# os-release/lsb gives more manageable and accurate output than issue, 
		# but mint should use issue for now.
		if ($b_os_release && !$b_mint){
			$distro = get_os_release();
			$b_osr = 1;
		}
		elsif ($b_lsb && !$b_mint){
			$distro = get_lsb_release();
		}
		else {
			# debian issue can end with weird escapes like \n \l
			$distro = (map {s/\\[a-z]|,|\*|\\||\"|[:\47]|^\s+|\s+$|n\/a//ig; $_} main::reader($issue))[0];
			# this handles an arch bug where /etc/arch-release is empty and /etc/issue 
			# is corrupted only older arch installs that have not been updated should 
			# have this fallback required, new ones use os-release
			if ( $distro =~ /arch linux/i){
				$distro = 'Arch Linux';
			}
		}
	}
	# a final check. If a long value, before assigning the debugger output, if os-release
	# exists then let's use that if it wasn't tried already. Maybe that will be better.
	# not handling the corrupt data, maybe later if needed
	if ($distro && length($distro) > 50 ){
		if (!$b_osr && $b_os_release){
			$distro = get_os_release();
		}
	}
	# test for /etc/lsb-release as a backup in case of failure, in cases 
	# where > one version/release file were found but the above resulted 
	# in null distro value. 
	if (!$distro){
		if ($b_os_release){
			$distro = get_os_release();
		}
		elsif ($b_lsb){
			$distro = get_lsb_release();
		}
	}
	# now some final null tries
	if (!$distro ){
		# if the file was null but present, which can happen in some cases, then use 
		# the file name itself to set the distro value. Why say unknown if we have 
		# a pretty good idea, after all?
		if ($distro_file){
			$distro_file =~ s/[-_]|release|version//g;
		}
	}
	## finally, if all else has failed, give up
	$distro ||= 'unknown';
	eval $end if $b_log;
	return $distro;
}
sub get_lsb_release {
	eval $start if $b_log;
	my ($distro,$id,$release,$codename,$description,) = ('','','','','');
	my @content = map {s/,|\*|\\||\"|[:\47]|^\s+|\s+$|n\/a//ig; $_} main::reader('/etc/lsb-release');
	foreach (@content){
		my @working = split /\s*=\s*/, $_;
		if ($working[0] eq 'DISTRIB_ID' && $working[1]){
			if ($working[1] =~ /^Arch$/i){
				$id = 'Arch Linux';
			}
			else {
				$id = $working[1];
			}
		}
		if ($working[0] eq 'DISTRIB_RELEASE' && $working[1]){
			$release = $working[1];
		}
		if ($working[0] eq 'DISTRIB_CODENAME' && $working[1]){
			$codename = $working[1];
		}
		# sometimes some distros cannot do their lsb-release files correctly, 
		# so here is one last chance to get it right.
		if ($working[0] eq 'DISTRIB_DESCRIPTION' && $working[1]){
			$description = $working[1];
		}
	}
	if (!$id && !$release && !$codename && $description){
		$distro = $description;
	}
	else {
		$distro = "$id $release $codename";
		$distro =~ s/^\s+|\s\s+|\s+$//g; # get rid of double and trailling spaces 
	}
	
	eval $end if $b_log;
	return $distro;
}
sub get_os_release {
	eval $start if $b_log;
	my ($pretty_name,$name,$version_name,$version_id,
	$distro_name,$distro) = ('','','','','','');
	my @content = map {s/\\||\"|[:\47]|^\s+|\s+$|n\/a//ig; $_} main::reader('/etc/os-release');
	foreach (@content){
		my @working = split /\s*=\s*/, $_;
		if ($working[0] eq 'PRETTY_NAME' && $working[1]){
			$pretty_name = $working[1];
		}
		if ($working[0] eq 'NAME' && $working[1]){
			$name = $working[1];
		}
		if ($working[0] eq 'VERSION' && $working[1]){
			$version_name = $working[1];
		}
		if ($working[0] eq 'VERSION_ID' && $working[1]){
			$version_id = $working[1];
		}
	}
	# NOTE: tumbleweed has pretty name but pretty name does not have version id
	if ($pretty_name && $pretty_name !~ /tumbleweed/i){
		$distro = $pretty_name;
	}
	elsif ($name){
		$distro = $name;
		if ($version_name){
			$distro .= ' ' . $version_name;
		}
		elsif ($version_id){
			$distro .= ' ' . $version_id;
		}
		
	}
	eval $end if $b_log;
	return $distro;
}
}

### END CODE REQUIRED BY THIS MODULE ##

### START MODULE CODE ##

### END MODULE CODE ##

### START TEST CODE ##

my @desktop = DesktopEnvironment::get();
print Dumper \@desktop;

