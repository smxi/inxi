#!/usr/bin/env perl
## File: system_debugger.pl
## Version: 2.7
## Date 2018-01-11
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

sub error_handler {
	my ($err, $message, $alt1) = @_;
	print "$err: $message err: $alt1\n";
}

sub check_program { return 1; }

# args: 1 - the file to create if not exists
sub toucher {
	my ($file ) = @_;
	if ( ! -e $file ){
		open( my $fh, '>', $file ) or error_handler('create', $file, $!);
	}
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
	print "Note: for dmidecode data you must be root.\n" if $b_root;
	print $line3;
	if (!$b_debug){
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
		my @ides = </proc/ide/*/*>;
		@files = (@files, @ides) if @ides;
	}
	else {
		push (@files, '/proc-ide-directory');
	}
	copy_files(\@files, 'disk');
	no warnings 'uninitialized';
	system("PATH=$ENV{'PATH'}
ls -l /dev > $data_dir/dev-data.txt 2>&1
ls -l /dev/disk > $data_dir/dev-disk-data.txt 2>&1
ls -l /dev/disk/by-id > $data_dir/dev-disk-id-data.txt 2>&1
ls -l /dev/disk/by-label > $data_dir/dev-disk-label-data.txt 2>&1
ls -l /dev/disk/by-uuid > $data_dir/dev-disk-uuid-data.txt 2>&1
# http://comments.gmane.org/gmane.linux.file-systems.zfs.user/2032
ls -l /dev/disk/by-wwn > $data_dir/dev-disk-wwn-data.txt 2>&1
ls -l /dev/disk/by-path > $data_dir/dev-disk-path-data.txt 2>&1
ls -l /dev/mapper > $data_dir/dev-disk-mapper-data.txt 2>&1
readlink /dev/root > $data_dir/dev-root.txt 2>&1
df -h -T -P --exclude-type=aufs --exclude-type=squashfs --exclude-type=unionfs --exclude-type=devtmpfs --exclude-type=tmpfs --exclude-type=iso9660 --exclude-type=devfs --exclude-type=linprocfs --exclude-type=sysfs --exclude-type=fdescfs > $data_dir/cmd-df-h-T-P-excludes.txt 2>&1
df -T -P --exclude-type=aufs --exclude-type=squashfs --exclude-type=unionfs --exclude-type=devtmpfs --exclude-type=tmpfs --exclude-type=iso9660 --exclude-type=devfs --exclude-type=linprocfs --exclude-type=sysfs --exclude-type=fdescfs > $data_dir/cmd-df-T-P-excludes.txt 2>&1
df -T -P --exclude-type=aufs --exclude-type=squashfs --exclude-type=unionfs --exclude-type=devtmpfs --exclude-type=tmpfs --exclude-type=iso9660 --exclude-type=devfs --exclude-type=linprocfs --exclude-type=sysfs --exclude-type=fdescfs --total > $data_dir/cmd-df-T-P-excludes-total.txt 2>&1
df -h -T > $data_dir/cmd-BSD-df-h-T-no-excludes.txt 2>&1
df -h > $data_dir/cmd-BSD-df-h-no-excludes.txt 2>&1
df -k -T > $data_dir/cmd-BSD-df-k-T-no-excludes.txt 2>&1
df -k > $data_dir/cmd-BSD-df-k-no-excludes.txt 2>&1
atacontrol list > $data_dir/cmd-BSD-atacontrol-list.txt 2>&1
camcontrol devlist > $data_dir/cmd-BSD-camcontrol-devlist.txt 2>&1
# bsd tool
mount > $data_dir/cmd-mount.txt 2>&1
if which btrfs >/dev/null 2>&1; then
	btrfs filesystem show  > $data_dir/cmd-btrfs-filesystem-show.txt 2>&1
	btrfs filesystem show --mounted  > $data_dir/cmd-btrfs-filesystem-show-mounted.txt 2>&1
	# btrfs filesystem show --all-devices > $data_dir/cmd-btrfs-filesystem-show-all-devices.txt 2>&1
else
	touch $data_dir/cmd-btrfs-absent
fi
gpart list > $data_dir/cmd-BSD-gpart-list.txt 2>&1
gpart show > $data_dir/cmd-BSD-gpart-show.txt 2>&1
gpart status > $data_dir/cmd-BSD-gpart-status.txt 2>&1
swapctl -l -k > $data_dir/cmd-BSD-swapctl-l-k.txt 2>&1
swapon -s > $data_dir/cmd-swapon-s.txt 2>&1
sysctl -b kern.geom.conftxt > $data_dir/cmd-BSD-sysctl-b-kern.geom.conftxt.txt 2>&1
sysctl -b kern.geom.confxml > $data_dir/cmd-BSD-sysctl-b-kern.geom.confxml.txt 2>&1
zfs list > $data_dir/cmd-zfs-list.txt 2>&1
zpool list > $data_dir/cmd-zpool-list.txt 2>&1
zpool list -v > $data_dir/cmd-zpool-list-v.txt 2>&1
df -P --exclude-type=aufs --exclude-type=squashfs --exclude-type=unionfs --exclude-type=devtmpfs --exclude-type=tmpfs --exclude-type=iso9660 > $data_dir/cmd-df-P-excludes.txt 2>&1
df -P > $data_dir/cmd-BSD-df-P-no-excludes.txt 2>&1
if which nvme >/dev/null 2>&1; then
	touch $data_dir/cmd-nvme-present
else
	touch $data_dir/cmd-nvme-absent
fi
");
}
sub display_data {
	my (%data,@files,@files2);
	my $working = '';
	if ( ! $b_display ){
		print "Warning: only some of the data collection can occur if you are not in X\n";
		system("touch $data_dir/warning-user-not-in-x");
	}
	if ( $b_root ){
		print "Warning: only some of the data collection can occur if you are running as Root user\n";
		system("touch $data_dir/warning-root-user");
	}
	print "Collecting Xorg log and xorg.conf files...\n";
	if ( -d "/etc/X11/xorg.conf.d/" ){
		@files = glob q("/etc/X11/xorg.conf.d/*");
	}
	else {
		@files = ('/xorg-conf-d');
	}
	push (@files, $files{'xorg-log'});
	push (@files, '/etc/X11/xorg.conf');
	copy_files(\@files,'xorg');
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
	);
	copy_data(\%data,'display');
	no warnings 'uninitialized';
	system("PATH=$ENV{'PATH'}
if which weston-info >/dev/null 2>&1; then
	weston-info > $data_dir/cmd-weston-info.txt 2>&1
else
	touch $data_dir/cmd-weston-info-absent
fi
if which weston >/dev/null 2>&1; then
	weston --version > $data_dir/cmd-weston-version.txt 2>&1
else
	touch $data_dir/cmd-weston-absent
fi
if which xprop >/dev/null 2>&1; then
	xprop -root > $data_dir/cmd-xprop_root.txt 2>&1
else
	touch $data_dir/cmd-xprop-absent
fi
if which glxinfo >/dev/null 2>&1; then
	glxinfo > $data_dir/cmd-glxinfo-full.txt 2>&1
	glxinfo -B > $data_dir/cmd-glxinfo-B.txt 2>&1
else
	touch $data_dir/cmd-glxinfo-absent
fi
if which xdpyinfo >/dev/null 2>&1; then
	xdpyinfo > $data_dir/cmd-xdpyinfo.txt 2>&1
else
	touch $data_dir/cmd-xdpyinfo-absent
fi
if which xrandr >/dev/null 2>&1; then
	xrandr > $data_dir/cmd-xrandr.txt 2>&1
else
	touch $data_dir/cmd-xrandr-absent
fi
if which X >/dev/null 2>&1; then
	X -version > $data_dir/cmd-x-version.txt 2>&1
else
	touch $data_dir/cmd-x-absent
fi
if which Xorg >/dev/null 2>&1; then
	Xorg -version > $data_dir/cmd-xorg-version.txt 2>&1
else
	touch $data_dir/cmd-xorg-absent
fi
if which kf5-config >/dev/null 2>&1; then
	kf5-config --version > $data_dir/cmd-kde-kf5-config-version-data.txt 2>&1
elif which kf6-config >/dev/null 2>&1; then
	kf6-config --version > $data_dir/cmd-kde-kf6-config-version-data.txt 2>&1
elif which kf$ENV{'KDE_SESSION_VERSION'}-config >/dev/null 2>&1; then
	kf$ENV{'KDE_SESSION_VERSION'}-config --version > $data_dir/cmd-kde-kf$ENV{'KDE_SESSION_VERSION'}-KSV-config-version-data.txt 2>&1
else
	touch $data_dir/cmd-kde-kf-config-absent
fi
if which plasmashell >/dev/null 2>&1; then
	plasmashell --version > $data_dir/cmd-kde-plasmashell-version-data.txt 2>&1
else
	touch $data_dir/cmd-kde-plasmashell-absent
fi
if which kwin_x11 >/dev/null 2>&1; then
	kwin_x11 --version > $data_dir/cmd-kde-kwin_x11-version-data.txt 2>&1
else
	touch $data_dir/cmd-kde-kwin_x11-absent
fi
if which kded4 >/dev/null 2>&1; then
	kded4 --version > $data_dir/cmd-kded4-version-data.txt 2>&1
elif which kded5 >/dev/null 2>&1; then
	kded5 --version > $data_dir/cmd-kded5-version-data.txt 2>&1
elif which kded >/dev/null 2>&1; then
	kded --version > $data_dir/cmd-kded-version-data.txt 2>&1
else
	touch $data_dir/cmd-kded-$ENV{'KDE_SESSION_VERSION'}-absent
fi
# kde 5/plasma desktop 5, this is maybe an extra package and won't be used
if which about-distro >/dev/null 2>&1; then
	about-distro > $data_dir/cmd-kde-about-distro.txt 2>&1
else
	touch $data_dir/cmd-kde-about-distro-absent
fi
if which loginctl >/dev/null 2>&1;then
	loginctl --no-pager list-sessions > $data_dir/cmd-loginctl-list-sessions.txt 2>&1
else
	touch $data_dir/cmd-loginctl-absent
fi
");
}
sub network_data {
	print "Collecting networking data...\n";
	no warnings 'uninitialized';
	system("PATH=$ENV{'PATH'}
if which ifconfig >/dev/null 2>&1;then
	ifconfig > $data_dir/cmd-ifconfig.txt 2>&1
else
	touch $data_dir/cmd-ifconfig-absent
fi
if which ip >/dev/null 2>&1;then
	ip addr > $data_dir/cmd-ip-addr.txt 2>&1
else
	touch $data_dir/cmd-ip-absent
fi
");
}
sub perl_modules {
	print "Collecting Perl module data (this can take a while)...\n";
	my @modules = ();
	my ($dirname,$holder,$mods,$value) = ('','','','');
	my $filename = 'perl-modules.txt';
	my @inc;
	foreach (sort @INC){
		# some BSD installs have . n @INC path
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
	
	no warnings 'uninitialized';
	system("PATH=$ENV{'PATH'}
# bsd tools http://cb.vu/unixtoolbox.xhtml
# freebsd
if which pciconf >/dev/null 2>&1;then
	pciconf -l -cv > $data_dir/cmd-BSD-pciconf-cvl.txt 2>&1
	pciconf -vl > $data_dir/cmd-BSD-pciconf-vl.txt 2>&1
	pciconf -l > $data_dir/cmd-BSD-pciconf-l.txt 2>&1
else
	touch $data_dir/cmd-BSD-pciconf-absent
fi
# openbsd
if which pcidump >/dev/null 2>&1;then
	pcidump > $data_dir/cmd-BSD-pcidump-openbsd.txt 2>&1
	pcidump -v > $data_dir/cmd-BSD-pcidump-v-openbsd.txt 2>&1
else
	touch $data_dir/cmd-BSD-pcidump-openbsd-absent
fi
# netbsd
if which pcictl >/dev/null 2>&1;then
	pcictl list > $data_dir/cmd-BSD-pcictl-list-netbsd.txt 2>&1
	pcictl list -n > $data_dir/cmd-BSD-pcictl-list-n-netbsd.txt 2>&1
else
	touch $data_dir/cmd-BSD-pcictl-netbsd-absent
fi
if which sysctl >/dev/null 2>&1;then
	sysctl -a > $data_dir/cmd-BSD-sysctl-a.txt 2>&1
else
	touch $data_dir/cmd-BSD-sysctl-absent
fi
if which usbdevs >/dev/null 2>&1;then
	usbdevs -v > $data_dir/cmd-BSD-usbdevs-v.txt 2>&1
else
	touch $data_dir/cmd-BSD-usbdevs-absent
fi
if which kldstat >/dev/null 2>&1;then
	kldstat > $data_dir/cmd-BSD-kldstat.txt 2>&1
else
	touch $data_dir/cmd-BSD-kldstat-absent
fi
# diskinfo -v <disk>
# fdisk <disk>
dmidecode > $data_dir/cmd-dmidecode.txt 2>&1
dmesg > $data_dir/cmd-dmesg.txt 2>&1
if which lscpu > /dev/null 2>&1;then
	lscpu > $data_dir/cmd-lscpu.txt 2>&1
else
	touch $data_dir/cmd-lscpu-absent
fi
if which lspci > /dev/null 2>&1;then
	lspci > $data_dir/cmd-lspci.txt 2>&1
	lspci -k > $data_dir/cmd-lspci-k.txt 2>&1
	lspci -knn > $data_dir/cmd-lspci-knn.txt 2>&1
	lspci -n > $data_dir/cmd-lspci-n.txt 2>&1
	lspci -nn > $data_dir/cmd-lspci-nn.txt 2>&1
	lspci -mm > $data_dir/cmd-lspci-mm.txt 2>&1
	lspci -mmnn > $data_dir/cmd-lspci-mmnn.txt 2>&1
	lspci -mmnnv > $data_dir/cmd-lspci-mmnnv.txt 2>&1
	lspci -v > $data_dir/cmd-lspci-v.txt 2>&1
else 
	touch $data_dir/cmd-lspci-absent
fi
if which lspci > /dev/null 2>&1;then
	lsusb > $data_dir/cmd-lsusb.txt 2>&1
else
	touch $data_dir/cmd-lsusb-absent
fi
if which hciconfig >/dev/null 2>&1;then
	hciconfig -a > $data_dir/cmd-hciconfig-a.txt 2>&1
else
	touch $data_dir/cmd-hciconfig-absent
fi
ps aux > $data_dir/cmd-ps-aux.txt 2>&1
ps -e > $data_dir/cmd-ps-e.txt 2>&1
ps -p 1 > $data_dir/cmd-ps-p-1.txt 2>&1
if which runlevel > /dev/null 2>&1;then
	runlevel > $data_dir/cmd-runlevel.txt 2>&1
else
	touch $data_dir/cmd-runlevel-absent
fi
if which rc-status >/dev/null 2>&1;then
	rc-status -a > $data_dir/cmd-rc-status-a.txt 2>&1
	rc-status -l > $data_dir/cmd-rc-status-l.txt 2>&1
	rc-status -r > $data_dir/cmd-rc-status-r.txt 2>&1
else
	touch $data_dir/cmd-rc-status-absent
fi
if which systemctl >/dev/null 2>&1;then
	systemctl list-units > $data_dir/cmd-systemctl-list-units.txt 2>&1
	systemctl list-units --type=target > $data_dir/cmd-systemctl-list-units-target.txt 2>&1
else
	touch $data_dir/cmd-systemctl-absent
fi
if which initctl >/dev/null 2>&1;then
	initctl list > $data_dir/cmd-initctl-list.txt 2>&1
else
	touch $data_dir/cmd-initctl-absent
fi
if which sensors >/dev/null 2>&1;then
	sensors > $data_dir/cmd-sensors.txt 2>&1
else
	touch $data_dir/cmd-sensors-absent
fi
if which strings >/dev/null 2>&1;then
	touch $data_dir/cmd-strings-present
else
	touch $data_dir/cmd-strings-absent
fi
# leaving this commented out to remind that some systems do not
# support strings --version, but will just simply hang at that command
# which you can duplicate by simply typing: strings then hitting enter, you will get hang.
# strings --version > $data_dir/strings.txt 2>&1
if which nvidia-smi >/dev/null 2>&1;then
	nvidia-smi -q > $data_dir/cmd-nvidia-smi-q.txt 2>&1
	nvidia-smi -q -x > $data_dir/cmd-nvidia-smi-xq.txt 2>&1
else
	touch $data_dir/cmd-nvidia-smi-absent
fi
echo $ENV{'CC'} > $data_dir/cmd-cc-content.txt 2>&1
ls /usr/bin/gcc* > $data_dir/cmd-gcc-sys-versions.txt 2>&1
if which gcc >/dev/null 2>&1;then
	gcc --version > $data_dir/cmd-gcc-version.txt 2>&1
else
	touch $data_dir/cmd-gcc-absent
fi
if which clang >/dev/null 2>&1;then
	clang --version > $data_dir/cmd-clang-version.txt 2>&1
else
	touch $data_dir/cmd-clang-absent
fi
if which systemd-detect-virt >/dev/null 2>&1;then
	systemd-detect-virt > $data_dir/cmd-systemd-detect-virt-info.txt 2>&1
else
	touch $data_dir/cmd-systemd-detect-virt-absent
fi
");
}
sub system_files {
	print "Collecting system files data...\n";
	
	no warnings 'uninitialized';
	# main::check_recommends() > $data_dir/check-recommends.txt 2>&1
	my (%data,@files,@files2);
	@files = RepoData::get($data_dir);
	copy_files(\@files, 'repo');
	# chdir "/etc";
	@files = glob q("/etc/*[-_]{[rR]elease,[vV]ersion}");
	push (@files, '/etc/issue');
	copy_files(\@files,'distro');
	@files = (
	'/etc/lsb-release',
	'/etc/os-release',
	'/proc/1/comm',
	'/proc/asound/cards',
	'/proc/asound/version',
	'/proc/cpuinfo',
	'/proc/meminfo',
	'/proc/modules',
	'/proc/net/arp',
	'/proc/version',
	);
	@files2=</sys/class/power_supply/*/uevent>;
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
	copy_files(\@files,'system-BSD');
	
	%data = (
	'size-indent' => $size{'indent'},
	'size-indent-min' => $size{'indent-min'},
	'size-cols-max' => $size{'max'},
	'xdg-config-home' => $ENV{'XDG_CONFIG_HOME'},
	'xdg-config-dirs' => $ENV{'XDG_CONFIG_DIRS'},
	'xdg-data-home' => $ENV{'XDG_DATA_HOME'},
	'xdg-data-dirs' => $ENV{'XDG_DATA_DIRS'},
	);
	@files2 = </proc/asound/card*/codec*>;
	if (@files2){
		my $asound = qx(head -n 1 /proc/asound/card*/codec* 2>&1);
		$data{'proc-asound-codecs'} = $asound;
	}
	else {
		$data{'proc-asound-codecs'} = undef;
	}
	my @sys = </sys/*>;
	if (@sys){
		$data{'sys-tree-ls-1-basic'} = join "\n", @sys;
	}
	else {
		$data{'sys-tree-ls-1-basic'} = undef;
	}
	copy_data(\%data,'system');
}
sub copy_data {
	my ($data_ref, $variant) = @_;
	my ($empty,$error,$fh,$good,$name,$undefined,$value);
	$variant = ( $variant ) ? "$variant-" : '';
	foreach (keys %$data_ref) {
		$value = $$data_ref{$_};
		$name = "$data_dir/data-$variant$_";
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

sub copy_files {
	my ($files_ref, $variant) = @_;
	my ($absent,$error,$good,$name,$unreadable);
	$variant = ( $variant ) ? "$variant-" : '';
	foreach (@$files_ref) {
		$name = $_;
		$name =~ s/^\///;
		$name =~ s/\//-/g;
		$name = "$data_dir/file-$variant$name";
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

sub run_self {
	print "Creating $self_name output file now. This can take a few seconds...\n";
	print "Starting $self_name from: $self_path\n";
	my $cmd = "$self_path/$self_name -FRfrploudmxxx -c 0 --debug 10 -y 120 > $data_dir/inxi-FRfrploudmxxxy120.txt 2>&1";
	system($cmd);
	copy($log_file, "$data_dir") or main::error_handler('copy-failed', "$log_file", "$!");
}

sub sys_tree {
	print "Constructing /sys tree data...\n";
	if ( main::check_program('tree') ){
		my $dirname = '/sys';
		my $cmd;
		system("tree -a -L 10 /sys > $data_dir/sys-tree-full-10.txt");
		opendir my($dh), $dirname or main::error_handler('open-dir',"$dirname", "$!");
		my @files = readdir $dh;
		closedir $dh;
		foreach (@files){
			next if /^\./;
			$cmd = "tree -a -L 10 $dirname/$_ > $data_dir/sys-tree-$_-10.txt";
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
		if ( $depth == 1 ){ '/sys/' }
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
	my $file = "$data_dir/sys-tree-ls-$depth.txt";
	open my $fh, '>', $file or main::error_handler('create',"$file", "$!");
	print $fh $output;
	close $fh;
	# print "$output\n";
}

sub sys_traverse_data {
	print "Parsing /sys files...\n";
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
	return if $File::Find::name =~ /\/(\.[a-z]|__|parameters\/|debug\/)/;
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
	my $filename = "sys-tree-parse.txt";
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
};1;

### END MODULE CODE ##

### START TEST CODE ##

my $ob_sys = SystemDebugger->new('full');
$ob_sys->run_debugger();
# $ob_sys->upload_file();
# $ob_sys->set_type('fred');
# SystemDebugger::upload_file('/home/harald/bin/scripts/inxi/svn/branches/inxi-perl/myfile.txt');
# $ob_sys->upload_file('/home/harald/bin/scripts/inxi/svn/branches/inxi-perl/myfile.txt');
