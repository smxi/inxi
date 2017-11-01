#!/usr/bin/env perl

# File: file_uploader.pl
# Version: 1.1
# Date 2017-10-31

use strict;
use warnings;
use 5.008;
use Net::FTP;

# args: 1 - path to file to be uploaded
sub upload_file {
	my ($fpath) = @_;
	my ($ftp, $host, $user, $pass, $dir, $fpath, $error);
	$host = "ftp.techpatterns.com";
	$user = "anonymous";
	$pass = "anonymous\@techpatterns.com";
	$dir = "incoming";
	# NOTE: important: must explicitly set to passive true/1
	$ftp = Net::FTP->new($host, Debug => 0, Passive => 1);
	$ftp->login($user, $pass) || die $ftp->message;
	$ftp->binary();
	$ftp->cwd($dir);
	print "Connected to FTP server.\n";
	$ftp->put($fpath) || die $ftp->message;
	$ftp->quit;
	print "Uploaded file $fpath.\n";
	print $ftp->message;
}
