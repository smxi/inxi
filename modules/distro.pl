#!/usr/bin/env perl
## File: distro.pl
## Version: 1.1
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
my $extra = 2;
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

sub clean_characters {
	my (@data) = @_;
	# newline, pipe, brackets, + sign, with space, then clear doubled
	# spaces and then strip out trailing/leading spaces.
	@data = map {s/\n|\|\+|\[\s\]|\s\s+/ /g; s/^\s+|\s+$//g; $_} @data;
	return @data;
}

### END CODE REQUIRED BY THIS MODULE ##

### START MODULE CODE ##

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
	
	return $distro;
	eval $end if $b_log;
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
	elsif ( $distro_file && -s $distro_file && $distro_file !~ /\/etc\/($exclude_s)$/){
		#print "$distro_file\n";
		if ($distro_file eq '/etc/SuSE-release'){
			$distro = (main::clean_characters( grep { /suse/i } main::reader($distro_file)))[0];
		}
		else {
			$distro = (main::reader($distro_file))[0];
		}
	}
	elsif (-f $issue){
		@working = main::reader($issue);
		my $b_mint = scalar (grep {/mint/i} @working); 
		if ($b_os_release && !$b_mint){
			$distro = get_os_release();
			$b_osr = 1;
		}
		elsif ($b_lsb && !$b_mint){
			$distro = get_lsb_release();
		}
		else {
		
		}
	}
	if (!$distro){
		if ($b_os_release){
			$distro = get_os_release();
		}
		elsif ($b_lsb){
			$distro = get_lsb_release();
		}
	}
	$distro ||= 'unknown';
	return $distro;
	eval $end if $b_log;
}
sub get_lsb_release {
	
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
### END MODULE CODE ##

### START TEST CODE ##

my $distro = DistroData::get();
print $distro, "\n";

