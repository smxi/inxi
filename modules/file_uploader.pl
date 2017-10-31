#!/usr/bin/env perl

# File: file_uploader.pl
# Version: 1.0
# Date 2017-10-29

use strict;
use warnings;
use 5.008;
use Net::FTP;

# args: 1 - path to file to be uploaded
sub upload_file {
	my ($path) = @_;
	my ($ftp, $host, $user, $pass, $dir, $fpath, $error);
	$host = "ftp.techpatterns.com";
	$user = "anonymous";
	$pass = "anonymous\@techpatterns.com";
	$dir = "incoming";
	# this is in live inxi, which passes the data via $ENV
	# normally, we'd pass this sub the path as an argument.
	if ($path == ''){
		$fpath = $ENV{debugger_file};
	}
	else {
		$fpath = $path;
	}
	
	# NOTE: important: must explicitly set to passive true/1
	$ftp = Net::FTP->new($host, Debug => 0, Passive => 1);
	$ftp->login($user, $pass) || die $ftp->message;
	$ftp->binary();
	$ftp->cwd($dir);
	print "Connected to FTP server.\n";
	$ftp->put($fpath) || die $ftp->message;
	$ftp->quit;
	print "Uploaded file.\n";
	print $ftp->message;
}
