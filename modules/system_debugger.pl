#!/usr/bin/env perl
## File: system_debugger.pl
## Version: 1.1
## Date 2017-12-16
## License: GNU GPL v3 or greater
## Copyright (C) 2017 Harald Hope

## INXI INFO ##
my $self_name='pinxi';
my $self_version='2.9.00';
my $self_date='2017-12-11';
my $self_patch='022-p';

use strict;
use warnings;
# use diagnostics;
use 5.008;

# use Net::FTP;

## stub functions
sub error_handler {

}
sub get_hostname {
	return 'tester';
}
# arg 1: type to return
sub get_defaults {
	my ($type) = @_;
	my %defaults = (
	'ftp-upload' => 'ftp.techpatterns.com/incoming',
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
sub check_recommends {}
sub get_repo_data {}

my $f = 'joe';
my $bsd_type = '';
my $bsd_version = '';
my $b_root = 0;
my $b_irc = 0;
my $self_data_dir = "$ENV{'HOME'}/.local/share/$self_name/";
my %size;
$size{'inner'} = 90;

my $line1 = "----------------------------------------------------------------------\n";
my $line2 = "======================================================================\n";
my $line3 = "----------------------------------------\n";

## Start actual logic

# NOTE: perl 5.008 needs package inside brackets.
# I believe 5.010 introduced option to have it outside brackets as you'd expect
{
package SystemDebugger;

use warnings;
use strict;
use diagnostics;
use 5.008;
use Net::FTP;
use File::Find q(find);
no warnings 'File::Find';
use File::Spec::Functions;
use POSIX qw(strftime);

my $type = 'full';
my $upload = '';
my $data_dir = '';
my $debug_dir = '';
my $debug_gz = '';
my @content = (); 

# args: 1 - type
# args: 2 - upload
sub new {
	my $class = shift;
	($type) = @_;
	my $self = {};
	print "$f\n";
	print "$type\n";
	return bless $self, $class;
}

sub run_debugger {
	print "Starting $self_name debugging data collector...\n";
	create_debug_directory();
	print "Note: for dmidecode data you must be root.\n" if $b_root;
	print $line3;
	disk_data();
	network_data();
	perl_modules();
	system_data();
	system_files();
	sys_traverse_data();
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
		$bsd_string = "-$bsd_type-$bsd_version";
	}
	$debug_dir = "$self_name$bsd_string-$host-$today$root_string";
	$debug_gz = "$debug_dir.tar.gz";
	$data_dir = "$self_data_dir$debug_dir";
	if ( -d $data_dir ){
		unlink $data_dir or main::error_handler('remove', "$data_dir", "$?");
	}
	mkdir $data_dir or main::error_handler('mkdir', "$data_dir", "$?");
	if ( -e "$self_data_dir$debug_gz" ){
		unlink "$self_data_dir$debug_gz" or main::error_handler('remove', "$self_data_dir$debug_gz", "$?");
	}
	print "Data going into: $data_dir\n";
}
sub compress_dir {
	print "Creating tar.gz compressed file of this material...\n";
	system("cd $self_data_dir
tar -czf $debug_gz $debug_dir
");
}
## NOTE: >/dev/null 2>&1 is sh, and &>/dev/null is bash, fix this
sub disk_data {
	print "Collecting dev, label, disk, uuid data, df...\n";
	no warnings 'uninitialized';
	system("PATH=$ENV{'PATH'}
ls -l /dev &> $data_dir/dev-data.txt
ls -l /dev/disk &> $data_dir/dev-disk-data.txt
ls -l /dev/disk/by-id &> $data_dir/dev-disk-id-data.txt
ls -l /dev/disk/by-label &> $data_dir/dev-disk-label-data.txt
ls -l /dev/disk/by-uuid &> $data_dir/dev-disk-uuid-data.txt
# http://comments.gmane.org/gmane.linux.file-systems.zfs.user/2032
ls -l /dev/disk/by-wwn &> $data_dir/dev-disk-wwn-data.txt
ls -l /dev/disk/by-path &> $data_dir/dev-disk-path-data.txt
ls -l /dev/mapper &> $data_dir/dev-disk-mapper-data.txt
readlink /dev/root &> $data_dir/dev-root.txt
df -h -T -P --exclude-type=aufs --exclude-type=squashfs --exclude-type=unionfs --exclude-type=devtmpfs --exclude-type=tmpfs --exclude-type=iso9660 --exclude-type=devfs --exclude-type=linprocfs --exclude-type=sysfs --exclude-type=fdescfs &> $data_dir/df-h-T-P-excludes.txt
df -T -P --exclude-type=aufs --exclude-type=squashfs --exclude-type=unionfs --exclude-type=devtmpfs --exclude-type=tmpfs --exclude-type=iso9660 --exclude-type=devfs --exclude-type=linprocfs --exclude-type=sysfs --exclude-type=fdescfs &> $data_dir/df-T-P-excludes.txt
df -T -P --exclude-type=aufs --exclude-type=squashfs --exclude-type=unionfs --exclude-type=devtmpfs --exclude-type=tmpfs --exclude-type=iso9660 --exclude-type=devfs --exclude-type=linprocfs --exclude-type=sysfs --exclude-type=fdescfs --total &> $data_dir/df-T-P-excludes-total.txt
df -h -T &> $data_dir/bsd-df-h-T-no-excludes.txt
df -h &> $data_dir/bsd-df-h-no-excludes.txt
df -k -T &> $data_dir/bsd-df-k-T-no-excludes.txt
df -k &> $data_dir/bsd-df-k-no-excludes.txt
atacontrol list &> $data_dir/bsd-atacontrol-list.txt
camcontrol devlist &> $data_dir/bsd-camcontrol-devlist.txt
# bsd tool
mount &> $data_dir/mount.txt
btrfs filesystem show  &> $data_dir/btrfs-filesystem-show.txt
btrfs filesystem show --mounted  &> $data_dir/btrfs-filesystem-show-mounted.txt
# btrfs filesystem show --all-devices  &> $data_dir/btrfs-filesystem-show-all-devices.txt
gpart list &> $data_dir/bsd-gpart-list.txt
gpart show &> $data_dir/bsd-gpart-show.txt
gpart status &> $data_dir/bsd-gpart-status.txt
swapctl -l -k &> $data_dir/bsd-swapctl-l-k.txt
swapon -s &> $data_dir/swapon-s.txt
sysctl -b kern.geom.conftxt &> $data_dir/bsd-sysctl-b-kern.geom.conftxt.txt
sysctl -b kern.geom.confxml &> $data_dir/bsd-sysctl-b-kern.geom.confxml.txt
zfs list &> $data_dir/zfs-list.txt
zpool list &> $data_dir/zpool-list.txt
zpool list -v &> $data_dir/zpool-list-v.txt
df -P --exclude-type=aufs --exclude-type=squashfs --exclude-type=unionfs --exclude-type=devtmpfs --exclude-type=tmpfs --exclude-type=iso9660 &> $data_dir/df-P-excludes.txt
df -P &> $data_dir/bsd-df-P-no-excludes.txt
cat /proc/mdstat &> $data_dir/proc-mdstat.txt
cat /proc/partitions &> $data_dir/proc-partitions.txt
cat /proc/scsi/scsi &> $data_dir/proc-scsi.txt
cat /proc/mounts &> $data_dir/proc-mounts.txt
cat /proc/mdstat &> $data_dir/proc-mdstat.txt
cat /proc/sys/dev/cdrom/info &> $data_dir/proc-cdrom-info.txt
ls /proc/ide/ &> $data_dir/proc-ide.txt
cat /proc/ide/*/* &> $data_dir/proc-ide-hdx-cat.txt
cat /etc/fstab &> $data_dir/etc-fstab.txt
cat /etc/mtab &> $data_dir/etc-mtab.txt
if which nvme &>/dev/null; then
	touch $data_dir/nvme-present
else
	touch $data_dir/nvme-absent
fi
");
}
sub network_data {
	print "Collecting networking data...\n";
	no warnings 'uninitialized';
	system("PATH=$ENV{'PATH'}
ifconfig &> $data_dir/ifconfig.txt
ip addr &> $data_dir/ip-addr.txt
");
}
sub perl_modules {
	print "Collecting Perl module data...\n";
	my @modules = ();
	my $mods = '';
	my $filename = 'perl-modules.txt';
# 	foreach (@INC){
# 		print "$_\n";
# 	}
	find { wanted => sub { push @modules, canonpath $_ if /\.pm\z/  }, no_chdir => 1 }, @INC;
	@modules = sort(@modules);
	foreach (@modules){
		$mods = $mods . $_ . "\n";
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
if which pciconf &>/dev/null;then
	pciconf -l -cv &> $data_dir/bsd-pciconf-cvl.txt
	pciconf -vl &> $data_dir/bsd-pciconf-vl.txt
	pciconf -l &> $data_dir/bsd-pciconf-l.txt
else
	touch $data_dir/bsd-pciconf-absent
fi
# openbsd
if which pcidump &>/dev/null;then
	pcidump &> $data_dir/bsd-pcidump-openbsd.txt
	pcidump -v &> $data_dir/bsd-pcidump-v-openbsd.txt
else
	touch $data_dir/bsd-pcidump-openbsd-absent
fi
# netbsd
if which pcictl &>/dev/null;then
	pcictl list &> $data_dir/bsd-pcictl-list-netbsd.txt
	pcictl list -n &> $data_dir/bsd-pcictl-list-n-netbsd.txt
else
	touch $data_dir/bsd-pcictl-netbsd-absent
fi
if which sysctl &>/dev/null;then
	sysctl -a &> $data_dir/bsd-sysctl-a.txt
else
	touch $data_dir/bsd-sysctl-absent
fi
if which usbdevs &>/dev/null;then
	usbdevs -v  &> $data_dir/bsd-usbdevs-v.txt
else
	touch $data_dir/bsd-usbdevs-absent
fi
if which kldstat &>/dev/null;then
	kldstat  &> $data_dir/bsd-kldstat.txt
else
	touch $data_dir/bsd-kldstat-absent
fi
# diskinfo -v <disk>
# fdisk <disk>
dmidecode &> $data_dir/dmidecode.txt
dmesg &> $data_dir/dmesg.txt
lscpu &> $data_dir/lscpu.txt
lspci &> $data_dir/lspci.txt
lspci -k &> $data_dir/lspci-k.txt
lspci -knn &> $data_dir/lspci-knn.txt
lspci -n &> $data_dir/lspci-n.txt
lspci -nn &> $data_dir/lspci-nn.txt
lspci -mm &> $data_dir/lspci-mm.txt
lspci -mmnn &> $data_dir/lspci-mmnn.txt
lspci -mmnnv &> $data_dir/lspci-mmnnv.txt
lspci -v &> $data_dir/lspci-v.txt
lsusb &> $data_dir/lsusb.txt
if which hciconfig &>/dev/null;then
	hciconfig -a &> $data_dir/hciconfig-a.txt
else
	touch $data_dir/hciconfig-absent
fi
ps aux &> $data_dir/ps-aux.txt
ps -e &> $data_dir/ps-e.txt
ps -p 1 &> $data_dir/ps-p-1.txt
runlevel &> $data_dir/runlevel.txt
if which rc-status &>/dev/null;then
	rc-status -a &> $data_dir/rc-status-a.txt
	rc-status -l &> $data_dir/rc-status-l.txt
	rc-status -r &> $data_dir/rc-status-r.txt
else
	touch $data_dir/rc-status-absent
fi
if which systemctl &>/dev/null;then
	systemctl list-units &> $data_dir/systemctl-list-units.txt
	systemctl list-units --type=target &> $data_dir/systemctl-list-units-target.txt
else
	touch $data_dir/systemctl-absent
fi
if which initctl &>/dev/null;then
	initctl list &> $data_dir/initctl-list.txt
else
	touch $data_dir/initctl-absent
fi
sensors &> $data_dir/sensors.txt
if which strings &>/dev/null;then
	touch $data_dir/strings-present
else
	touch $data_dir/strings-absent
fi
# leaving this commented out to remind that some systems do not
# support strings --version, but will just simply hang at that command
# which you can duplicate by simply typing: strings then hitting enter, you will get hang.
# strings --version  &> $data_dir/strings.txt
if which nvidia-smi &>/dev/null;then
	nvidia-smi -q &> $data_dir/nvidia-smi-q.txt
	nvidia-smi -q -x &> $data_dir/nvidia-smi-xq.txt
else
	touch $data_dir/nvidia-smi-absent
fi
echo $ENV{'CC'} &> $data_dir/cc-content.txt
ls /usr/bin/gcc* &> $data_dir/gcc-sys-versions.txt
if which gcc &>/dev/null;then
	gcc --version &> $data_dir/gcc-version.txt
else
	touch $data_dir/gcc-absent
fi
if which clang &>/dev/null;then
	clang --version &> $data_dir/clang-version.txt
else
	touch $data_dir/clang-absent
fi
if which systemd-detect-virt &>/dev/null;then
	systemd-detect-virt &> $data_dir/systemd-detect-virt-info.txt
else
	touch $data_dir/systemd-detect-virt-absent
fi
");
}
sub system_files {
	print "Collecting system files data...\n";
	# main::get_repo_data($data_dir);
	# main::check_recommends() &> $data_dir/check-recommends.txt
	no warnings 'uninitialized';
# id_dir='/sys/class/power_supply/' 
# ids=$( ls \$id_dir 2>/dev/null )
# if [[ -n $ids ]];then
# 	for batid in \$ids 
# 	do
# 		cat $id_dir$batid'/uevent' &> $data_dir/sys-power-supply-$batid.txt
# 	done
# else
# 	touch $data_dir/sys-power-supply-none
# fi
# if which shopt &>/dev/null;then
# 	shopt -s nullglob
# 	a_distro_ids=(/etc/*[-_]{release,version})
# 	shopt -u nullglob
# 	echo ${a_distro_ids[@]} &> $data_dir/etc-distro-files.txt
# 	for distro_file in ${a_distro_ids[@]} /etc/issue
# 	do
# 		if [[ -f $distro_file ]];then
# 			cat $distro_file &> $data_dir/distro-file${distro_file//\//-}
# 		fi
# 	done
# fi
	
	system("PATH=$ENV{'PATH'}
cat /proc/1/comm &> $data_dir/proc-1-comm.txt
head -n 1 /proc/asound/card*/codec* &> $data_dir/proc-asound-card-codec.txt
if [[ -f /proc/version ]];then
	cat /proc/version &> $data_dir/proc-version.txt
else
	touch $data_dir/proc-version-absent
fi
cat /etc/src.conf &> $data_dir/bsd-etc-src-conf.txt
cat /etc/make.conf &> $data_dir/bsd-etc-make-conf.txt
cat /etc/issue &> $data_dir/etc-issue.txt
cat /etc/lsb-release &> $data_dir/lsb-release.txt
cat /etc/os-release &> $data_dir/os-release.txt
cat /proc/asound/cards &> $data_dir/proc-asound-device.txt
cat /proc/asound/version &> $data_dir/proc-asound-version.txt
cat /proc/cpuinfo &> $data_dir/proc-cpu-info.txt
cat /proc/meminfo &> $data_dir/proc-meminfo.txt
cat /proc/modules &> $data_dir/proc-modules.txt
cat /proc/net/arp &> $data_dir/proc-net-arp.txt 
# bsd data
cat /var/run/dmesg.boot &> $data_dir/bsd-var-run-dmesg.boot.txt 
echo $size{'inner'} &> $data_dir/cols-inner.txt
echo $ENV{'XDG_CONFIG_HOME'} &> $data_dir/xdg_config_home.txt
echo $ENV{'XDG_CONFIG_DIRS'} &> $data_dir/xdg_config_dirs.txt
echo $ENV{'XDG_DATA_HOME'} &> $data_dir/xdg_data_home.txt
echo $ENV{'XDG_DATA_DIRS'} &> $data_dir/xdg_data_dirs.txt
# just on the off chance bsds start having a fake /sys
ls -w 1 /sys &> $data_dir/sys-ls-1.txt
");
}

sub sys_traverse_data {
	print $line3;
	print "Parsing /sys files...\n";
	find( \&wanted, "/sys");
	process_data( @content );
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
	push @content, $File::Find::name;
	return;
}
sub process_data {
	my ($data,$fh,$result,$row,$sep);
	my $filename = "sys-traverse.txt";
	# no sorts, we want the order it comes in
	# @content = sort @content; 
	foreach (@content){
		$data='';
		$sep='';
		open($fh, "<$_");
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
	print $line3;
	my ($self, $ftp_url) = @_;
	my ($ftp, $domain, $host, $user, $pass, $dir, $error);
	$ftp_url ||= main::get_defaults('ftp-upload');
	print "Uploading to: $ftp_url\n";
	$ftp_url =~ s/\/$//g; # trim off trailing slash if present
	my @url = split(/\//, $ftp_url);
	my $file_path = "$self_data_dir$debug_gz";
	$host = $url[0];
	$dir = $url[1];
	$domain = $host;
	$domain =~ s/^ftp\.//;
	$user = "anonymous";
	$pass = "anonymous\@$domain";
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
# upload_file('/home/harald/bin/scripts/inxi/svn/branches/inxi-perl/myfile.txt');

};
1;
my $ob_sys = SystemDebugger->new('full','upload');
$ob_sys->run_debugger();
$ob_sys->upload_file();
# $ob_sys->set_type('fred');
# SystemDebugger::upload_file('/home/harald/bin/scripts/inxi/svn/branches/inxi-perl/myfile.txt');
# $ob_sys->upload_file('/home/harald/bin/scripts/inxi/svn/branches/inxi-perl/myfile.txt');
