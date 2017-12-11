#!/usr/bin/env perl
## File: updater.pl
## Version: 1.0
## Date 2017-12-11
## License: GNU GPL v3 or greater
## Copyright (C) 2017 Harald Hope

## required program/variable placeholders

my $self_name='pinxi';
my $self_version='2.9.00';
my $self_date='2017-12-11';
my $self_patch='019-p';

sub error_handler {
	my ($err, $message, $alt1) = @_;
	
}
sub download_file {

}


## actual updater logic


# args: 1 - download url, not including file name; 2 - string to print out
# 3 - update type option
# note that 1 must end in / to properly construct the url path
sub update_me {
	eval $start;
	my ( $self_download, $download_id ) = @_;
	my $downloader_error=1;
	my $file_contents='';
	my $output = '';
	my $full_self_path = "$self_path/$self_name";
	
	if ( $b_irc ){
		error_handler('not-tty', "Sorry, you can't run the $self_name self updater option (-$3) in an IRC client." );;
	}
	if ( ! -w $full_self_path ){
		error_handler('permissions', "Updater $self_name", '');
	}
	$output = "${output}Starting $self_name self updater.\n";
	$output = "${output}Starting $self_name self updater.\n";
	$output = "${output}Currently running $self_name version number: $self_version\n";
	$output = "${output}Current version patch number: $self_patch\n";
	$output = "${output}Current version release date: $self_date\n";
	$output = "${output}Updating $self_name in $self_path using $download_id as download source...\n";
	print $output;
	$output = '';
	$self_download = "$self_download/$self_name";
	$file_contents=download_file('stdout', $self_download);
	
	# then do the actual download
	if (  $file_contents ){
		# make sure the whole file got downloaded and is in the variable
		if ( $file_contents =~ /###\*\*EOF\*\*###/ ){
			open(my $fh, '>', $full_self_path);
			print $fh $file_contents or error_handler();
			close $fh;
			qx( chmod +x '$self_path/$self_name' );
			set_version_data();
			$output = "${output}Successfully updated to $download_id version: $self_version\n";
			$output = "${output}New $download_id version patch number: $self_patch\n";
			$output = "${output}New $download_id version release date: $self_date\n";
			$output = "${output}To run the new version, just start $self_name again.\n";
			$output = "${output}$line3\n";
			$output = "${output}Starting download of man page file now.\n";
			print $output;
			$output = '';
			update_man();
			exit 1;
		}
		else {
			error_handler(16, '');
		}
	}
	# now run the error handlers on any downloader failure
	else {
		if ( $download_id eq 'source server' ){
			error_handler(8, "$downloader_error");
		}
		elsif ( $download_id eq 'alt server' ){
			error_handler( 10, "$self_download");
		}
		else {
			error_handler(12, "$self_download");
		}
	}
	eval $end;
}

sub update_man {
	my $man_file_url="https://github.com/smxi/inxi/raw/master/$self_name.1.gz";
	my $man_file_location=set_man_location();
	my $man_file_path="$man_file_location/$self_name.1.gz" ;
	my $output = '';
	my $downloader_man_error=1;
	if ( ! $b_man ){
		print "Skipping man download because branch version is being used.\n";
		return 0;
	}
	if ( ! -d $man_file_location ){
		print "The required man directory was not detected on your system.\n";
		print "Unable to continue: $man_file_location\n";
		return 0;
	}
	if ( -w $man_file_location ){
		print "Cannot write to $man_file_location! Are you root?\n";
		print "Unable to continue: $man_file_location\n";
		return 0;
	}
	
	if ( -f "/usr/share/man/man8/inxi.8.gz" ){
		print "Updating man page location to man1.\n";
		rename "/usr/share/man/man8/inxi.8.gz", "$man_file_location/inxi.1.gz";
		if ( check_program('mandb') ){
			system( 'mandb' );
		}
	}
		if ( $dl{'dl'} =~ /tiny|wget/){
			print "Checking Man page download URL...\n";
			download_file('spider', '', $man_file_url);
			$downloader_man_error = $?;
		}
	if ( $downloader_man_error == 1 ){
		if ( $dl{'dl'} =~ /tiny|wget/){
			print "Man file download URL verified: $man_file_url\n";
		}
		print "Downloading Man page file now.\n";
		download_file('file', $self_download, $man_file_url);
		$downloader_man_error = $?;
		if ( $downloader_man_error == 0 ){
			print "Oh no! Something went wrong downloading the Man gz file at: $man_file_url\n";
			print "Check the error messages for what happened. Error: $downloader_man_error\n";
		}
		else {
			print "Download/install of man page successful. Check to make sure it works: man inxi\n";
		}
	}
	else {
		print "Man file download URL failed, unable to continue: $man_file_url\n";
	}
}

sub get_update_url {
	my ($type) = @_;
	my @urls = (
	'https://github.com/smxi/inxi/raw/inxi-perl/',
	# 'https://github.com/smxi/inxi/raw/one/',
	# 'https://github.com/smxi/inxi/raw/two/',
	);
	if ( $urls[$type] ){
		return $urls[$type];
	}
}

sub set_man_location {
	my $location='';
	my $default_location='/usr/share/man/man1';
	my $man_paths=qx(man --path 2>/dev/null);
	my $man_local='/usr/local/share/man';
	my $b_use_local=0;
	if ( $man_paths && $man_paths =~ /$man_local/ ){
		$b_use_local=1;
	}
	# for distro installs
	if ( -f "$default_location/inxi.1.gz" ){
		$location=$default_location;
	}
	else {
		if ( $b_use_local ){
			if ( ! -d "$man_local/man1" ){
				mkdir "$man_local/man1";
			}
			$location="$man_local/man1";
		}
	}
	if ( ! $location ){
		$location=$default_location;
	}
	return $location;
}

# update for updater output version info
# note, this is only now used for self updater function so it can get
# the values from the UPDATED file, NOT the running program!
sub set_version_data {
	open (my $fh, '<', "$self_path/$self_name");
	while( my $row = <$fh>){
		chomp $row;
		$row =~ s/'//g;
		if ($row =~ /^my \$self_name/ ){
			$self_name = (split /=/, $row)[1];
		}
		elsif ($row =~ /^my \$self_version/ ){
			$self_version = (split /=/, $row)[1];
		}
		elsif ($row =~ /^my \$self_date/ ){
			$self_date = (split /=/, $row)[1];
		}
		elsif ($row =~ /^my \$self_patch/ ){
			$self_patch = (split /=/, $row)[1];
		}
		elsif ($row =~ /infobash/){
			last;
		}
	}
	close $fh;
}
