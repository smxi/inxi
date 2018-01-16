#!/usr/bin/env perl
## File: system_debugger.pl
## Version: 3.0
## Date 2018-01-15
## License: GNU GPL v3 or greater
## Copyright (C) 2017-18 Harald Hope

## INXI INFO ##
my $self_name='pinxi';
my $self_version='2.9.00';
my $self_date='2017-12-11';
my $self_patch='022-p';
my $self_path = "$ENV{'HOME'}/bin/scripts/inxi/svn/branches/inxi-perl";

use strict;
use warnings;
# use diagnostics;
use 5.008;
use File::Find;
use Data::Dumper qw(Dumper); # print_r

# use Net::FTP;

### START DEFAULT CODE ##


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

### END DEFAULT CODE ##

### START CODE REQUIRED BY THIS MODULE ##

sub check_recommends {}

# returns count of files in directory, if 0, dir is empty
sub count_dir_files {
	return undef unless -d $_[0];
	opendir my $dh, $_[0] or error_handler('open-dir-failed', "$_[0]", $!); 
	my $count = grep { ! /^\.{1,2}/ } readdir $dh; # strips out . and ..
	return $count;
}
# arg 1: type to return
sub get_defaults {
	my ($type) = @_;
	my %defaults = (
	'ftp-upload' => 'ftp.tobechpatterns.com/incoming',
	# 'inxi-branch-1' => 'https://github.com/smxi/inxi/raw/one/',
	# 'inxi-branch-2' => 'https://github.com/smxi/inxi/raw/two/',
	'inxi-main' => 'https://github.com/smxi/inxi/raw/inxi-perl/',
	'inxi-man' => "https://github.com/smxi/inxi/raw/master/$self_name.1.gz",
	);
	if ( exists $defaults{$type}){
		return $defaults{$type};
	}
	else {
		error_handler('bad-arg', $type);
	}
}
sub get_hostname {
	return 'tester';
}
{
package RepoData;
sub get{}
}

my $f = 'joe';
my $bsd_type = '';
my $os = '';
my $b_display = 1;
my $b_root = 0;
my $b_irc = 0;
my $user_data_dir = "$ENV{'HOME'}/.local/share/$self_name";
my %size;
$size{'inner'} = 90;
my $log_file = "$ENV{'HOME'}/.local/share/$self_name/$self_name.log";
my $start = '';
my $end = '';

my %files = (
'asound-cards'   => '/proc/asound/cards',
'asound-modules' => '/proc/asound/modules',
'asound-version' => '/proc/asound/version',
'cpuinfo'        => '/proc/cpuinfo',
'dmesg-boot'     => '/var/run/dmesg.boot',
'lsb-release'    => '/etc/lsb-release',
'mdstat'         => '/proc/mdstat',
'meminfo'        => '/proc/meminfo',
'modules'        => '/proc/modules',
'mounts'         => '/proc/mounts',
'os-release'     => '/etc/os-release',
'partitions'     => '/proc/partitions',
'scsi'           => '/proc/scsi/scsi',
'version'        => '/proc/version',
'xorg-log'       => '/var/log/Xorg.0.log' # or xset path
);

my $line1 = "----------------------------------------------------------------------\n";
my $line2 = "======================================================================\n";
my $line3 = "----------------------------------------\n";

### START MODULE CODE ##

# NOTE: perl 5.008 needs package inside brackets.
# I believe 5.010 introduced option to have it outside brackets as you'd expect
# SystemDebugger
{
package SystemDebugger;

# use warnings;
# use strict;
# use diagnostics;
# use 5.008;
# use Net::FTP; # never load until needed

# use File::Find q(find);
#no warnings 'File::Find';
# use File::Spec::Functions;
#use File::Copy;
#use POSIX qw(strftime);

my $type = 'full';
my $upload = '';
my $data_dir = '';
my $debug_dir = '';
my $debug_gz = '';
my @content = (); 
my $b_debug = 0;
my $b_delete_dir = 1;
# args: 1 - type
# args: 2 - upload
sub new {
	my $class = shift;
	($type) = @_;
	my $self = {};
	# print "$f\n";
	# print "$type\n";
	return bless $self, $class;
}

sub run_debugger {
	require File::Copy;
	import File::Copy;
	require File::Spec::Functions;
	import File::Spec::Functions;
	
	print "Starting $self_name debugging data collector...\n";
	create_debug_directory();
	print "Note: for dmidecode data you must be root.\n" if !$b_root;
	print $line3;
	if (!$b_debug){
		audio_data();
		disk_data();
		display_data();
		network_data();
		perl_modules();
		system_data();
	}
	system_files();
	print $line3;
	if (!$b_debug){
		if ( -d '/sys' && main::count_dir_files('/sys') ){
			sys_tree();
			sys_traverse_data();
		}
		else {
			print "Skipping /sys data collection. /sys not present, or empty.\n";
		}
		print $line3;
	}
	run_self();
	print $line3;
	compress_dir();
}

sub create_debug_directory {
	my $host = main::get_hostname();
	$host =~ s/ /-/g;
	$host ||= 'no-host';
	my $bsd_string = '';
	my $root_string = '';
	# note: Time::Piece was introduced in perl 5.9.5
	my ($sec,$min,$hour,$mday,$mon,$year) = localtime;
	$year = $year+1900;
	$mon += 1;
	if (length($sec)  == 1) {$sec = "0$sec";}
	if (length($min)  == 1) {$min = "0$min";}
	if (length($hour) == 1) {$hour = "0$hour";}
	if (length($mon)  == 1) {$mon = "0$mon";}
	if (length($mday) == 1) {$mday = "0$mday";}
	
	my $today = "$year-$mon-${mday}_$hour$min$sec";
	# my $date = strftime "-%Y-%m-%d_", localtime;
	if ($b_root){
		$root_string = '-root';
	}
	if ( $bsd_type ){
		$bsd_string = "-$bsd_type-$os";
	}
	$debug_dir = "$self_name$bsd_string-$host-$today$root_string";
	$debug_gz = "$debug_dir.tar.gz";
	$data_dir = "$user_data_dir/$debug_dir";
	if ( -d $data_dir ){
		unlink $data_dir or main::error_handler('remove', "$data_dir", "$!");
	}
	mkdir $data_dir or main::error_handler('mkdir', "$data_dir", "$!");
	if ( -e "$user_data_dir/$debug_gz" ){
		#rmdir "$user_data_dir$debug_gz" or main::error_handler('remove', "$user_data_dir/$debug_gz", "$!");
		print "Failed removing leftover directory:\n$user_data_dir$debug_gz error: $?" if system('rm','-rf',"$user_data_dir$debug_gz");
	}
	print "Data going into: $data_dir\n";
}
sub compress_dir {
	print "Creating tar.gz compressed file of this material...\n";
	print "File: $debug_gz\n";
	system("cd $user_data_dir; tar -czf $debug_gz $debug_dir");
	print "Removing $data_dir...\n";
	#rmdir $data_dir or print "failed removing: $data_dir error: $!\n";
	return 1 if !$b_delete_dir;
	if (system('rm','-rf',$data_dir) ){
		print "Failed removing: $data_dir\nError: $?\n";
	}
	else {
		print "Directory removed.\n";
	}
}
# NOTE: incomplete, don't know how to ever find out 
# what sound server is actually running, and is in control
sub audio_data {
	my (%data,@files,@files2);
	print "Collecting audio data...\n";
	my @cmds = (
	['aplay', '-l'], # alsa
	['pactl', 'list'], # pulseaudio
	);
	run_commands(\@cmds,'audio');
	@files = glob('/proc/asound/card*/codec*');
	if (@files){
		my $asound = qx(head -n 1 /proc/asound/card*/codec* 2>&1);
		$data{'proc-asound-codecs'} = $asound;
	}
	else {
		$data{'proc-asound-codecs'} = undef;
	}
	write_data(\%data,'audio');
	@files = (
	'/proc/asound/cards',
	'/proc/asound/version',
	);
	copy_files(\@files,'audio');
}
## NOTE: >/dev/null 2>&1 is sh, and &>/dev/null is bash, fix this
# ls -w 1 /sysrs > tester 2>&1
sub disk_data {
	my (%data,@files,@files2);
	print "Collecting dev, label, disk, uuid data, df...\n";
	@files = (
	'/etc/fstab',
	'/etc/mtab',
	'/proc/mdstat',
	'/proc/mounts',
	'/proc/partitions',
	'/proc/scsi/scsi',
	'/proc/sys/dev/cdrom/info',
	);
	if (-d '/proc/ide/'){
		my @ides = glob('/proc/ide/*/*');
		@files = (@files, @ides) if @ides;
	}
	else {
		push (@files, '/proc-ide-directory');
	}
	copy_files(\@files, 'disk');
	my @cmds = (
	['btrfs', 'filesystem show'],
	['btrfs', 'filesystem show --mounted'],
	# ['btrfs', 'filesystem show --all-devices'],
	['df', '-h -T -P --exclude-type=aufs --exclude-type=squashfs --exclude-type=unionfs --exclude-type=devtmpfs --exclude-type=tmpfs --exclude-type=iso9660 --exclude-type=devfs --exclude-type=linprocfs --exclude-type=sysfs --exclude-type=fdescfs '],
	['df', '-T -P --exclude-type=aufs --exclude-type=squashfs --exclude-type=unionfs --exclude-type=devtmpfs --exclude-type=tmpfs --exclude-type=iso9660 --exclude-type=devfs --exclude-type=linprocfs --exclude-type=sysfs --exclude-type=fdescfs'],
	['df', '-T -P --exclude-type=aufs --exclude-type=squashfs --exclude-type=unionfs --exclude-type=devtmpfs --exclude-type=tmpfs --exclude-type=iso9660 --exclude-type=devfs --exclude-type=linprocfs --exclude-type=sysfs --exclude-type=fdescfs --total'],
	['df', '-h -T'],
	['df', '-h'],
	['df', '-k -T'],
	['df', '-k'],
	['df', '-P --exclude-type=aufs --exclude-type=squashfs --exclude-type=unionfs --exclude-type=devtmpfs --exclude-type=tmpfs --exclude-type=iso9660 '],
	['df', '-P'],
	['gpart', 'list'],
	['gpart', 'show'],
	['gpart', 'status'],
	['ls', '-l /dev'],
	['ls', '-l /dev/disk'],
	['ls', '-l /dev/disk/by-id'],
	['ls', '-l /dev/disk/by-label'],
	['ls', '-l /dev/disk/by-uuid'],
	# http://comments.gmane.org/gmane.linux.file-systems.zfs.user/2032
	['ls', '-l /dev/disk/by-wwn'],
	['ls', '-l /dev/disk/by-path'],
	['ls', '-l /dev/mapper'],
	['mount', ''],
	['nvme', 'present'],
	['readlink', '/dev/root'],
	['swapon', '-s'],
	['zfs', 'list'],
	['zpool', 'list'],
	['zpool', 'list -v'],
	);
	run_commands(\@cmds,'disk');
	@cmds = (
	['atacontrol', 'list'],
	['camcontrol', 'devlist'],
	['swapctl', '-l -k'],
	);
	run_commands(\@cmds,'disk-bsd');
}
sub display_data {
	my (%data,@files,@files2);
	my $working = '';
	if ( ! $b_display ){
		print "Warning: only some of the data collection can occur if you are not in X\n";
		main::toucher("$data_dir/display-data-warning-user-not-in-x");
	}
	if ( $b_root ){
		print "Warning: only some of the data collection can occur if you are running as Root user\n";
		main::toucher("touch $data_dir/display-data-warning-root-user");
	}
	print "Collecting Xorg log and xorg.conf files...\n";
	if ( -d "/etc/X11/xorg.conf.d/" ){
		@files = glob("/etc/X11/xorg.conf.d/*");
	}
	else {
		@files = ('/xorg-conf-d');
	}
	push (@files, $files{'xorg-log'});
	push (@files, '/etc/X11/xorg.conf');
	copy_files(\@files,'display-xorg');
	print "Collecting X, xprop, glxinfo, xrandr, xdpyinfo data, wayland, weston...\n";
	%data = (
	'desktop-session' => $ENV{'DESKTOP_SESSION'},
	'gdmsession' => $ENV{'GDMSESSION'},
	'gnome-desktop-session-id' => $ENV{'GNOME_DESKTOP_SESSION_ID'},
	'kde3-full-session' => $ENV{'KDE_FULL_SESSION'},
	'xdg-current-desktop' => $ENV{'XDG_CURRENT_DESKTOP'},
	'kde-gte-4-session-version' => $ENV{'KDE_SESSION_VERSION'},
	'xdg-session-desktop' => $ENV{'XDG_SESSION_DESKTOP'},
	# wayland data collectors:
	'xdg-session-type' => $ENV{'XDG_SESSION_TYPE'},
	'wayland-display' =>  $ENV{'WAYLAND_DISPLAY'},
	'gdk-backend' => $ENV{'GDK_BACKEND'},
	'qt-qpa-platform' => $ENV{'QT_QPA_PLATFORM'},
	'clutter-backend' => $ENV{'CLUTTER_BACKEND'},
	'sdl-videodriver' => $ENV{'SDL_VIDEODRIVER'},
	# program display values
	'size-indent' => $size{'indent'},
	'size-indent-min' => $size{'indent-min'},
	'size-cols-max' => $size{'max'},
	);
	write_data(\%data,'display');
	my @cmds = (
	# kde 5/plasma desktop 5, this is maybe an extra package and won't be used
	['about-distro',''],
	['glxinfo',''],
	['glxinfo','-B'],
	['kded','--version'],
	['kded4','--version'],
	['kded5','--version'],
	['kded6','--version'],
	['kf4-config','--version'],
	['kf5-config','--version'],
	['kf6-config','--version'],
	['kwin_x11','--version'],
	['loginctl','--no-pager list-sessions'],
	['nvidia-smi','-q'],
	['nvidia-smi','-q -x'],
	['plasmashell','--version'],
	['weston-info',''],
	['weston','--version'],
	['xdpyinfo',''],
	['Xorg','-version'],
	['xprop','-root'],
	['xrandr',''],
	);
	run_commands(\@cmds,'display');
}
sub network_data {
	print "Collecting networking data...\n";
# 	no warnings 'uninitialized';
	my @cmds = (
	['ifconfig',''],
	['ip','addr'],
	);
	run_commands(\@cmds,'network');
}
sub perl_modules {
	print "Collecting Perl module data (this can take a while)...\n";
	my @modules = ();
	my ($dirname,$holder,$mods,$value) = ('','','','');
	my $filename = 'perl-modules.txt';
	my @inc;
	foreach (sort @INC){
		# some BSD installs have '.' n @INC path
		if (-d $_ && $_ ne '.'){
			$_ =~ s/\/$//; # just in case, trim off trailing slash
			$value .= "EXISTS: $_\n";
			push @inc, $_;
		} 
		else {
			$value .= "ABSENT: $_\n";
		}
	}
	main::writer("$data_dir/perl-inc-data.txt",$value);
	File::Find::find { wanted => sub { 
		push @modules, File::Spec->canonpath($_) if /\.pm\z/  
	}, no_chdir => 1 }, @inc;
	@modules = sort(@modules);
	foreach (@modules){
		my $dir = $_;
		$dir =~ s/[^\/]+$//;
		if (!$holder || $holder ne $dir ){
			$holder = $dir;
			$value = "DIR: $dir\n";
			$_ =~ s/^$dir//;
			$value .= " $_\n";
		}
		else {
			$value = $_;
			$value =~ s/^$dir//;
			$value = " $value\n";
		}
		$mods .= $value;
	}
	open (my $fh, '>', "$data_dir/$filename");
	print $fh $mods;
	close $fh;
}
sub system_data {
	print "Collecting system data...\n";
	my %data = (
	'cc' => $ENV{'CC'},
	'xdg-config-home' => $ENV{'XDG_CONFIG_HOME'},
	'xdg-config-dirs' => $ENV{'XDG_CONFIG_DIRS'},
	'xdg-data-home' => $ENV{'XDG_DATA_HOME'},
	'xdg-data-dirs' => $ENV{'XDG_DATA_DIRS'},
	);
	my @files = glob('/usr/bin/gcc*');
	if (@files){
		$data{'gcc-versions'} = join "\n",@files;
	}
	else {
		$data{'gcc-versions'} = undef;
	}
	@files = </sys/*>;
	if (@files){
		$data{'sys-tree-ls-1-basic'} = join "\n", @files;
	}
	else {
		$data{'sys-tree-ls-1-basic'} = undef;
	}
	write_data(\%data,'system');
	# bsd tools http://cb.vu/unixtoolbox.xhtml
	my @cmds = (
	# general
	['sysctl', '-b kern.geom.conftxt'],
	['sysctl', '-b kern.geom.confxml'],
	['usbdevs','-v'],
	# freebsd
	['pciconf','-l -cv'],
	['pciconf','-vl'],
	['pciconf','-l'],
	# openbsd
	['pcidump',''],
	['pcidump','-v'],
	# netbsd
	['kldstat',''],
	['pcictl','list'],
	['pcictl','list -ns'],
	);
	run_commands(\@cmds,'system-bsd');
	# diskinfo -v <disk>
	# fdisk <disk>
	@cmds = (
	['clang','--version'],
	['dmidecode',''],
	['dmesg',''],
	['gcc','--version'],
	['hciconfig','-a'],
	['initctl','list'],
	['lscpu',''],
	['lspci','-k'],
	['lspci','-knn'],
	['lspci','-knnv'],# returns ports
	['lspci','-n'],
	['lspci','-nn'],
	['lspci','-nnk'],
	['lspci','-mm'],
	['lspci','-mmk'],
	['lspci','-mmkv'],
	['lspci','-mmnn'],
	['lspci','-v'],
	['lspci',''],
	['lsusb',''],
	['lsusb','-v'],
	['ps','aux'],
	['ps','-e'],
	['ps','-p 1'],
	['runlevel',''],
	['rc-status','-a'],
	['rc-status','-l'],
	['rc-status','-r'],
	['sensors',''],
	# leaving this commented out to remind that some systems do not
	# support strings --version, but will just simply hang at that command
	# which you can duplicate by simply typing: strings then hitting enter.
	# ['strings','--version'],
	['strings','present'],
	['sysctl','-a'],
	['systemctl','list-units'],
	['systemctl','list-units --type=target'],
	['systemd-detect-virt',''],
	);
	run_commands(\@cmds,'system');
}
sub system_files {
	print "Collecting system files data...\n";
	# main::check_recommends() > $data_dir/check-recommends.txt 2>&1
	my (%data,@files,@files2);
	@files = RepoData::get($data_dir);
	copy_files(\@files, 'repo');
	# chdir "/etc";
	@files = glob q("/etc/*[-_]{[rR]elease,[vV]ersion}");
	push (@files, '/etc/issue');
	push (@files, '/etc/lsb-release');
	push (@files, '/etc/os-release');
	copy_files(\@files,'system-distro');
	@files = (
	'/proc/1/comm',
	'/proc/cpuinfo',
	'/proc/meminfo',
	'/proc/modules',
	'/proc/net/arp',
	'/proc/version',
	);
	@files2=glob('/sys/class/power_supply/*/uevent');
	if (@files2){
		@files = (@files,@files2);
	}
	else {
		push (@files, '/sys-class-power-supply-empty');
	}
	copy_files(\@files, 'system');
	@files = (
	'/etc/make.conf',
	'/etc/src.conf',
	'/var/run/dmesg.boot',
	);
	copy_files(\@files,'system-bsd');
	
}

sub copy_files {
	my ($files_ref, $type) = @_;
	my ($absent,$error,$good,$name,$unreadable);
	foreach (@$files_ref) {
		$name = $_;
		$name =~ s/^\///;
		$name =~ s/\//-/g;
		$name = "$data_dir/$type-file-$name";
		$good = $name . '.txt';
		$absent = $name . '-absent';
		$error = $name . '-error';
		$unreadable = $name . '-unreadable';
		if (-e $_ ) {
			if (-r $_){
				copy($_,"$good") or main::toucher($error);
			}
			else {
				main::toucher($unreadable);
			}
		}
		else {
			main::toucher($absent);
		}
	}
}

sub run_commands {
	my ($cmds,$type) = @_;
	my $holder = '';
	my ($name,$cmd,$args);
	foreach (@$cmds){
		my @rows = @$_;
		if (my $program = main::check_program($rows[0])){
			if ($rows[1] eq 'present'){
				$name = "$data_dir/$type-cmd-$rows[0]-present";
				main::toucher($name);
			}
			else {
				$args = $rows[1];
				$args =~ s/\s|--|\/|=/-/g; # for:
				$args =~ s/--/-/g;# strip out -- that result from the above
				$args =~ s/^-//g;
				$args = "-$args" if $args;
				$name = "$data_dir/$type-cmd-$rows[0]$args.txt";
				$cmd = "$program $rows[1] >$name 2>&1";
				system($cmd);
			}
		}
		else {
			if ($holder ne $rows[0]){
				$name = "$data_dir/$type-cmd-$rows[0]-absent";
				main::toucher($name);
				$holder = $rows[0];
			}
		}
	}
}
sub write_data {
	my ($data_ref, $type) = @_;
	my ($empty,$error,$fh,$good,$name,$undefined,$value);
	foreach (keys %$data_ref) {
		$value = $$data_ref{$_};
		$name = "$data_dir/$type-data-$_";
		$good = $name . '.txt';
		$empty = $name . '-empty';
		$error = $name . '-error';
		$undefined = $name . '-undefined';
		if (defined $value) {
			if ($value || $value eq '0'){
				open($fh, '>', $good) or main::toucher($error);
				print $fh "$value";
			}
			else {
				main::toucher($empty);
			}
		}
		else {
			main::toucher($undefined);
		}
	}
}

sub run_self {
	print "Creating $self_name output file now. This can take a few seconds...\n";
	print "Starting $self_name from: $self_path\n";
	my $cmd = "$self_path/$self_name -FRfrploudmxxx -c 0 --debug 10 -y 120 > $data_dir/$self_name-FRfrploudmxxxy120.txt 2>&1";
	system($cmd);
	copy($log_file, "$data_dir") or main::error_handler('copy-failed', "$log_file", "$!");
}

sub sys_tree {
	print "Constructing /sys tree data...\n";
	if ( main::check_program('tree') ){
		my $dirname = '/sys';
		my $cmd;
		system("tree -a -L 10 /sys > $data_dir/sys-data-tree-full-10.txt");
		opendir my($dh), $dirname or main::error_handler('open-dir',"$dirname", "$!");
		my @files = readdir $dh;
		closedir $dh;
		foreach (@files){
			next if /^\./;
			$cmd = "tree -a -L 10 $dirname/$_ > $data_dir/sys-data-tree-$_-10.txt";
			#print "$cmd\n";
			system($cmd);
		}
	}
	else {
		sys_ls(1);
		sys_ls(2);
		sys_ls(3);
		sys_ls(4);
	}
}
sub sys_ls {
	my ( $depth) = @_;
	my $cmd = do {
		if ( $depth == 1 ){ 'ls -l /sys/ 2>/dev/null' }
		elsif ( $depth == 2 ){ 'ls -l /sys/*/ 2>/dev/null' }
		elsif ( $depth == 3 ){ 'ls -l /sys/*/*/ 2>/dev/null' }
		elsif ( $depth == 4 ){ 'ls -l /sys/*/*/*/ 2>/dev/null' }
		elsif ( $depth == 5 ){ 'ls -l /sys/*/*/*/*/ 2>/dev/null' }
		elsif ( $depth == 5 ){ 'ls -l /sys/*/*/*/*/ 2>/dev/null' }
	};
	my @working = ();
	my $output = '';
	my ($type);
	my $result = qx($cmd);
	open my $ch, '<', \$result or main::error_handler('open-data',"$cmd", "$!");
	while ( my $line = <$ch> ){
		chomp($line);
		$line =~ s/^\s+|\s+$//g;
		@working = split /\s+/, $line;
		$working[0] ||= '';
		if ( scalar @working > 7 ){
			if ($working[0] =~ /^d/ ){
				$type = "d - ";
			}
			elsif ($working[0] =~ /^l/){
				$type = "l - ";
			}
			else {
				$type = "f - ";
			}
			$working[9] ||= '';
			$working[10] ||= '';
			$output = $output . "  $type$working[8] $working[9] $working[10]\n";
		}
		elsif ( $working[0] !~ /^total/ ){
			$output = $output . $line . "\n";
		}
	}
	close $ch;
	my $file = "$data_dir/sys-data-ls-$depth.txt";
	open my $fh, '>', $file or main::error_handler('create',"$file", "$!");
	print $fh $output;
	close $fh;
	# print "$output\n";
}

sub sys_traverse_data {
	print "Parsing /sys files...\n";
	# get rid pointless error:Can't cd to (/sys/kernel/) debug: Permission denied
	no warnings 'File::Find';
	File::Find::find( \&wanted, "/sys");
	process_data();
}
sub wanted {
	return if -d; # not directory
	return unless -e; # Must exist
	return unless -r; # Must be readable
	return unless -f; # Must be file
	# note: a new file in 4.11 /sys can hang this, it is /parameter/ then
	# a few variables. Since inxi does not need to see that file, we will
	# not use it. Also do not need . files or __ starting files
	# print $File::Find::name . "\n";
	# block maybe: cfgroup\/
	return if $File::Find::name =~ /\/(\.[a-z]|kernel\/|parameters\/|debug\/)/;
	# comment this one out if you experience hangs or if 
	# we discover syntax of foreign language characters
	# Must be ascii like. This is questionable and might require further
	# investigation, it is removing some characters that we might want
	return unless -T; 
	# print $File::Find::name . "\n";
	push (@content, $File::Find::name);
	return;
}
sub process_data {
	my ($data,$fh,$result,$row,$sep);
	my $filename = "sys-data-parse.txt";
	# no sorts, we want the order it comes in
	# @content = sort @content; 
	foreach (@content){
		$data='';
		$sep='';
		open($fh, '<', $_);
		while ($row = <$fh>) {
			chomp $row;
			$data .= $sep . '"' . $row . '"';
			$sep=', ';
		}
		$result .= "$_:[$data]\n";
		# print "$_:[$data]\n"
	}
	# print scalar @content . "\n";
	open ($fh, '>', "$data_dir/$filename");
	print $fh $result;
	close $fh;
	# print $fh "$result";
}
# args: 1 - path to file to be uploaded
# args: 2 - optional: alternate ftp upload url
# NOTE: must be in format: ftp.site.com/incoming
sub upload_file {
	require Net::FTP;
	import Net::FTP;
	my ($self, $ftp_url) = @_;
	my ($ftp, $domain, $host, $user, $pass, $dir, $error);
	$ftp_url ||= main::get_defaults('ftp-upload');
	$ftp_url =~ s/\/$//g; # trim off trailing slash if present
	my @url = split(/\//, $ftp_url);
	my $file_path = "$user_data_dir/$debug_gz";
	$host = $url[0];
	$dir = $url[1];
	$domain = $host;
	$domain =~ s/^ftp\.//;
	$user = "anonymous";
	$pass = "anonymous\@$domain";
	
	print $line3;
	print "Uploading to: $ftp_url\n";
	# print "$host $domain $dir $user $pass\n";
	print "File to be uploaded: $file_path\n";
	
	if ($host && ( $file_path && -e $file_path ) ){
		# NOTE: important: must explicitly set to passive true/1
		$ftp = Net::FTP->new($host, Debug => 0, Passive => 1);
		$ftp->login($user, $pass) || main::error_handler('ftp-login', $ftp->message);
		$ftp->binary();
		$ftp->cwd($dir);
		print "Connected to FTP server.\n";
		$ftp->put($file_path) || main::error_handler('ftp-upload', $ftp->message);
		$ftp->quit;
		print "Uploaded file successfully!\n";
		print $ftp->message;
	}
	else {
		main::error_handler('ftp-bad-path', "$file_path");
	}
}
}

### END MODULE CODE ##

### START TEST CODE ##

my $ob_sys = SystemDebugger->new('full');
#$ob_sys->run_debugger();
# $ob_sys->upload_file();
# $ob_sys->set_type('fred');
# SystemDebugger::upload_file('/home/harald/bin/scripts/inxi/svn/branches/inxi-perl/myfile.txt');
# $ob_sys->upload_file('/home/harald/bin/scripts/inxi/svn/branches/inxi-perl/myfile.txt');
