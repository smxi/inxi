#!/usr/bin/env perl
## File: repos.pl
## Version: 1.0
## Date 2018-01-10
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

### START CODE REQUIRED BY THIS MODULE ##

### END CODE REQUIRED BY THIS MODULE ##

### START MODULE CODE ##

{
package RepoData;
my $num = 0;
my (@content,@data,@data2,@data3,@repos,@repo_files,@dbg_files,$working,$debugger_dir);

sub get {
	my ($debugger_dir) = @_;
	if ($bsd_type){
		get_repos_bsd();
	}
	else {
		get_repos_linux();
	}
	if ($debugger_dir){
		return @dbg_files;
	}
	else {
		if (!@repos){
			my $pm = (!$bsd_type) ? 'package manager': 'OS type';
			@data = (
			{$num++ . '#Alert' => "No repo data detected. Does $self_name support your $pm?"},
			);
			@repos = (@data);
		}
		return @repos;
	}
}

sub get_repos_linux {
	eval $start if $b_log;
	my $apt = '/etc/apt/sources.list';
	my $pacman = '/etc/pacman.conf';
	# BSDs
	my $bsd_pkg = '/usr/local/etc/pkg/repos/';
	my $freebsd = '/etc/freebsd-update.conf';
	my $freebsd_pkg = '/etc/pkg/FreeBSD.conf';
	my $netbsd = '/usr/pkg/etc/pkgin/repositories.conf';
	my $openbsd = '/etc/pkg.conf';
	
	# apt - debian, buntus, also sometimes some yum/rpm repos may create 
	# apt repos here as well
	if (-f $apt || -d "$apt.d"){
		@repo_files = </etc/apt/sources.list.d/*.list>;
		push @repo_files, $apt;
		log_data('apt repo files: ' . join('; ', @repo_files) ) if $b_log;
		foreach ( sort @repo_files){
			repo_builder($_,'apt','^\s*deb') if -r $_;
		}
	}
	# pacman: Arch and derived
	if (-f $pacman){
		@repo_files = grep {/^\s*Include/i} main::reader($pacman);
		@repo_files = map {
			$_ =~ s/^\s+|\s+$//g; 
			my @working = split( /\s+=\s+/, $_); 
			$working[1];
		} @repo_files;
		@repo_files = sort(@repo_files);
		@repo_files = uniq(@repo_files);
		foreach (sort @repo_files){
			if (-f $_){
				repo_builder($_,'pacman','^[[:space:]]*Server','\s+=\s+',1);
			}
			else {
				push @dbg_files, $_ if $debugger_dir;
				@data = (
				{$num++ . "#File listed in" => $pacman},
				[("$_ does not seem to exist.")],
				);
				@repos = (@repos,@data);
			}
		}
	}
	# print Dumper \@repos;
	eval $end if $b_log;
}
sub get_repos_bsd {
	eval $start if $b_log;
	my $bsd_pkg = '/usr/local/etc/pkg/repos/';
	my $freebsd = '/etc/freebsd-update.conf';
	my $freebsd_pkg = '/etc/pkg/FreeBSD.conf';
	my $netbsd = '/usr/pkg/etc/pkgin/repositories.conf';
	my $openbsd = '/etc/pkg.conf';
	my $ports =  '/etc/portsnap.conf';
	
	if ( -f $ports || -f $freebsd || -d $bsd_pkg){
		if ( -f $ports ) {
			repo_builder($ports,'ports','^\s*SERVERNAME','\s+=\s+',1);
		}
		if ( -f $freebsd ){
			repo_builder($ports,'freebsd','^\s*ServerName','\s+',1);
		}
		if ( -f $freebsd_pkg ){
			repo_builder($ports,'freebsd-pkg','^\s*url',':\s+',1);
		}
		if ( -d $bsd_pkg){
			@repo_files = </usr/local/etc/pkg/repos/*.conf>;
			if (@repo_files){
				my ($url);
				foreach (@repo_files){
					push @dbg_files, $_ if $debugger_dir;
					# these will be result sets separated by an empty line
					# first dump all lines that start with #
					@content = grep { /^\s*[^#]/ } main::reader($_);
					# then do some clean up on the lines
					@content = map { $_ =~ s/^\s+|{|}|,|\*|\s+$//g; } main::reader($_);
					# get all rows not starting with a # and starting with a non space character
					my $url = '';
					foreach (@content){
						if (!/^\s*$/){
							my @data2 = split /\s*:\s*/, $_;
							@data2 = map { $_ =~ s/^\s+|\s+$//g; $_; } @data2;
							$url = "$data2[1]:$data2[2]" if $data2[0] eq 'url';
							#print "url:$url\n" if $url;
							if ($url && $data2[0] eq 'enabled'){
								if ($data2[1] eq 'yes'){
									push @data3, "$url"
								}
								$url = '';
							}
						}
					}
					@data3 = ('No pkg enabled servers found in file') if ! @data3;
					@data = (
					{$num++ . "#BSD pkg enabled servers" => $_},
					[@data3],
					);
					@repos = (@repos,@data);
					@data3 = ();
				}
			}
		}
	}
	elsif (-f $openbsd) {
		repo_builder($ports,'openbsd','^installpath','\s+=\s+',1);
	}
	elsif (-f $netbsd){
		# not an empty row, and not a row starting with #
		repo_builder($ports,'netbsd','^\s*[^#]+$');
	}
	
	eval $start if $b_log;
}
sub repo_builder {
	my ($file,$type,$search,$split,$count) = @_;
	my ($missing,$key);
	my %unfound = (
	'apt' => 'No repos found in this file',
	'bsd-package' => 'No package servers found in this file',
	'pacman' => 'No repos found in this file',
	'ports' => 'No ports servers found in this file',
	'freebsd' => 'No update servers found in this file',
	'freebsd-pkg' => 'No default pkg server found in this file',
	'openbsd' => 'No pkg mirrors found in this file',
	'netbsd' => 'No pkg servers found in this file',
	);
	$missing = $unfound{$type};
	my %keys = (
	'apt' => 'Active apt sources in',
	'bsd-package' => 'BSD pkg server',
	'pacman' => 'Active Pacman repo servers in',
	'freebsd' => 'FreeBSD update server',
	'freebsd-pkg' => 'FreeBSD default pkg server',
	'ports' => 'BSD ports server',
	'openbsd' => 'OpenBSD pkg mirror',
	'netbsd' => 'NetBSD pkg servers',
	);
	$key = $keys{$type};

	push @dbg_files, $file if $debugger_dir;
	@content = grep {/$search/i} main::reader($file);
	@content = data_cleaner(@content);
	if ($split){
		@content = map { my @inner = split (/$split/, $_);$inner[$count]} @content;
	}
	@content = url_cleaner(@content);
	@content = ($missing) if ! @content;
	@data = (
	{$num++ . "#$key" => $file},
	[@content],
	);
	@repos = (@repos,@data);
}
sub data_cleaner {
	my (@content) = @_;
	# basics: trim white space, get rid of double spaces
	@content = map { $_ =~ s/^\s+|\s+$//g; $_ =~ s/\s\s+/ /g; $_} @content;
	return @content;
}
# clean if irc
sub url_cleaner {
	my (@content) = @_;
	@content = map { $_ =~ s/:\//: \//; $_} @content if $b_irc;
	return @content;
}
sub file_path {
	my ($filename,$dir) = @_;
	my ($working);
	$working = $filename;
	$working =~ s/^\///;
	$working =~ s/\//-/g;
	$working = "$dir/file-repo-$working.txt";
	return $working;
}
};1;

### END MODULE CODE ##

my @result = RepoData::get();
print Dumper \@result;

### START TEST CODE ##



