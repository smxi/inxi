#!/usr/bin/env perl

# File: ls_dir.p1
# Date 2017-10-31

use strict;
use warnings;
use 5.008;

use DirHandle;

sub ls_dir {
	my ($target, $dir_output, $file_output) = @_;
	my $content = '';
	
# 	my $working = new DirHandle $target;
# 	if (defined $working){
# 		while (defined($_ = $working->read)){ 
# 			something($_); 
# 		}
# # 		$working->rewind;
# # 		while (defined($_ = $working->read)){
# # 			something_else($_);
# # 		}
# 		undef $working;
# 	}
	foreach my $file ( glob "$target" ) {
		if (-l $file){
			if ( -d $file ){
				$content .= 'ld: ' . $file . " => " . readlink($file) . "\n";
			}
			elsif ( -f $file ){
				$content .= 'lf: ' . $file. " => " . readlink($file) . "\n";
			}
		}
		else {
			if ( -d $file ){
				$content .= 'd:  ' . $file . "\n";
			}
			elsif ( -f $file ){
				$content .= 'f:  ' . $file . "\n";
			}
		}
	}
	if ($file_output){
		print_contents($dir_output, $file_output, $content);
	}
	else {
		print $content;
	}
}
# $dir must be an absolute path, not ~/... etc
sub print_contents {
	my ($dir, $file, $content) = @_;
	my $fpath = $dir . $file;
	print "Writing to $fpath\n";
	open(my $fh, '>', $fpath) or die "Could not open file '$fpath' $!";
	print $fh $content;
	close $fh;
}

ls_dir('/sys/*/*/*/*', '/home/harald/bin/scripts/inxi/svn/branches/inxi-perl/', 'sys-4.txt');
