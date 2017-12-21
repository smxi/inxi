#!/usr/bin/perl
## File: start_client.pl
## Version: 1.0
## Date 2017-12-20
## License: GNU GPL v3 or greater
## Copyright (C) 2017 Harald Hope

## stub code

my %irc_client = (
'client' => '',
'console' => 0,
'dcop' => 0,
'konvi' => 0,
'qdbus' => 0,
'version' => '',
);

sub log_data {}

sub program_version {
	my ($app, $search, $num) = @_;
	my ($cmd,$line,$output);
	my $version_nu = '';
	my $version = '--version';
	if ( $num > 0 ){
		$num--;
	}
	if ( $app =~ /^dwm|ksh|scrotwm|spectrwm$/ ) {
		$version = '-v';
	}
	elsif ($app eq 'epoch' ){
		$version = 'version';
	}
	# note, some wm/apps send version info to stderr instead of stdout
	if ( $app =~ /^dwm|ksh|scrotwm$/ ) {
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
	log_data("app version command: $cmd");
	$output = qx($cmd);
	# sample: dwm-5.8.2, ©.. etc, why no space? who knows. Also get rid of v in number string
	# xfce, and other, output has , in it, so dump all commas and parentheses
	if ($output){
		open my $ch, '<', \$output or die "failed to open: error: $!";
		while (<$ch>){
			#chomp;
			if ( $_ =~ /$search/i ) {
				$_ = trimmer($_);
				# print "$_ ::$num\n";
				$version_nu = (split /\s+/, $_)[$num];
				$version_nu =~ s/(,|dwm-|wmii2-|wmii-|v|V|\(|\))//g;
				# print "$version_nu\n";
				last;
			}
		}
		close $ch if $ch;
	}
	log_data("Program version: $version_nu");
	return $version_nu;
}

sub trimmer {
	my $str = shift;
	$str =~ s/^\s+|\s+$|\n$//g; 
	return $str;
}

## real code

{
package StartClient;

}1;
