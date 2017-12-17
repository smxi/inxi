#!/usr/bin/env perl
## File: system_debugger.pl
## Version: 1.0
## Date 2017-12-12
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

my $f = 'joe';

## Start actual logic

# NOTE: perl 5.008 needs package inside brackets.
# I believe 5.010 introduced option to have it outside brackets as you'd expect
{
package SystemDebugger;

use warnings;
use strict;
use 5.008;
use Net::FTP;
use File::Find;

my $type = 'full';

sub new {
	my $class = shift;
	$type = shift;
	my $self = {};
	print "$f\n";
	print "$type\n";
	return bless $self, $class;
}
sub set_type {
	my $self = shift;
	$type = shift;
	print "$type\n";
}
# args: 1 - path to file to be uploaded
# args: 2 - optional: alternate ftp upload url
# NOTE: must be in format: ftp.site.com/incoming
sub upload_file {
	my ($self, $file_path, $ftp_url) = @_;
	my ($ftp, $domain, $host, $user, $pass, $dir, $error);
	$ftp_url ||= main::get_defaults('ftp-upload');
	print "fm: $ftp_url\n";
	$ftp_url =~ s/\/$//g; # trim off trailing slash if present
	my @url = split(/\//, $ftp_url);
	$host = $url[0];
	$dir = $url[1];
	$domain = $host;
	$domain =~ s/^ftp\.//;
	$user = "anonymous";
	$pass = "anonymous\@$domain";
	print "$host $domain $dir $user $pass\n";
	print "$file_path\n";
	
	if ($host && ( $file_path && -e $file_path ){
		# NOTE: important: must explicitly set to passive true/1
		$ftp = Net::FTP->new($host, Debug => 0, Passive => 1);
		$ftp->login($user, $pass) || die $ftp->message;
		$ftp->binary();
		$ftp->cwd($dir);
		print "Connected to FTP server.\n";
		$ftp->put($file_path) || die $ftp->message;
		$ftp->quit;
		print "Uploaded file $file_path.\n";
		print $ftp->message;
	}
	else {
		print "host/file path incorrect!!\n";
	}
}
# upload_file('/home/harald/bin/scripts/inxi/svn/branches/inxi-perl/myfile.txt');

};
1;
my $ob_sys = SystemDebugger->new('fred');
# $ob_sys->set_type('fred');
# SystemDebugger::upload_file('/home/harald/bin/scripts/inxi/svn/branches/inxi-perl/myfile.txt');
# $ob_sys->upload_file('/home/harald/bin/scripts/inxi/svn/branches/inxi-perl/myfile.txt');
