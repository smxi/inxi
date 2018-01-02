#!/usr/bin/env perl
## File: show_options.pl
## Version: 1.7
## Date 2018-01-01
## License: GNU GPL v3 or greater
## Copyright (C) 2017 Harald Hope

use strict;
use warnings;
# use diagnostics;
use 5.008;

## NOTE: Includes dummy sub and variables to allow for running for debugging.

my ($b_irc, $bsd_type);
my $self_name = 'pinxi';
my $ps_count = 5;
my $b_weather = 'true';
my $b_update = 'true';
my %size( 'max' => 100 );
my $start = '';
my $end = '';

sub print_screen_line {
	my $line = shift;
	print $line;
}

# arg 1: type to return
sub get_defaults {
	my ($arg) = @_;
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
		error_handler('bad-arg', $arg);
	}
}


## start actual code

sub show_options {
	if ( $b_irc ){
		error_handler('not-in-irc', 'help');
	}
	my ($type) = @_;
	my (@row,@rows,@data);
	my $line = '';
	my $color_scheme_count=12; # $(( ${#A_COLOR_SCHEMES[@]} - 1 ));
	my $partition_string='partition';
	my $partition_string_u='Partition';
	if ( $bsd_type ){
		$partition_string='slice';
		$partition_string_u='Slice';
	}
	# fit the line to the screen!
	for my $i ( 0 .. ( ( $size{'max'} / 2 ) - 2 ) ){
		$line = $line . '- ';
	}
	@rows = (
	['0', '', '', "$self_name supports the following options. You can combine 
	them, or list them one by one. Examples: $self_name^-v4^-c6 OR 
	$self_name^-bDc^6. If you start $self_name with no arguments, it will show 
	the short form." ],
	[0, '', '', '' ],
	['0', '', '', "The following options if used without -F, -b, or -v will show 
	just option line(s): A, B, C, D, G, I, M, N, P, R, S, f, i, m, n, o, p, l, 
	u, r, s, t - you can use these alone or together to show just the line(s) 
	you want to see. If you use them with -v^[level], -b or -F, it will show the 
	full output for that line along with the output for the chosen verbosity level." ],
	['0', '', '', $line ],
	['0', '', '', "Output Control Options:" ],
	['1', '-A', '--audio', "Audio/sound card information." ],
	['1', '-b', '--basic', "Basic output, short form. Like $self_name^-v^2, only minus hard 
	disk names." ],
	['1', '-B', '--battery', "Battery info, shows charge, condition, plus extra information 
	(if battery present)." ],
	['1', '-c', '--color', "Color schemes. Scheme number is required. Color selectors run a 
	color selector option prior to $self_name starting which lets you set the 
	config file value for the selection." ],
	['1', '', '', "Supported color schemes: 0-$color_scheme_count 
	Example:^$self_name^-c^11" ],
	['1', '', '', "Color selectors for each type display (NOTE: irc and global only 
	show safe color set):" ],
	['2', '94', '', "Console, out of X" ],
	['2', '95', '', "Terminal, running in X - like xTerm" ],
	['2', '96', '', "Gui IRC, running in X - like Xchat, Quassel, Konversation etc." ],
	['2', '97', '', "Console IRC running in X - like irssi in xTerm" ],
	['2', '98', '', "Console IRC not in  X" ],
	['2', '99', '', "Global - Overrides/removes all settings. Setting specific 
	removes global." ],
	['1', '-C', '--cpu', "CPU output, including per CPU clockspeed and max CPU speed 
	(if available)." ],
	['1', '-d', '--optical', "Optical drive data (and floppy disks, if present). Same as -Dd. 
	See also -x and -xx." ],
	['1', '-D', '--disk', "Full hard Disk info, not only model, ie: /dev/sda ST380817AS 
	80.0GB. See also -x and -xx. Disk total used percentage includes swap 
	partition size(s)." ],
	['1', '-f', '--flags', "All cpu flags, triggers -C. Not shown with -F to avoid spamming. 
	ARM cpus show 'features'." ],
	['1', '-F', '--full', "Full output for $self_name. Includes all Upper Case line letters, 
	plus -s and -n. Does not show extra verbose options like 
	-d -f -l -m -o -p -r -t -u -x" ],
	['1', '-G', '--graphics', "Graphic card information (card, display server type/version, 
	resolution, renderer, OpenGL version)." ],
	['1', '-i', '--ip', "Wan IP address, and shows local interfaces (requires ifconfig 
	network tool). Same as -Nni. Not shown with -F for user security reasons, 
	you shouldn't paste your local/wan IP." ],
	['1', '-I', '--info', "Information: processes, uptime, memory, irc client (or shell type),
	$self_name version." ],
	['1', '-l', '--label', "$partition_string_u labels. Default: short $partition_string -P. 
	For full -p output, use: -pl (or -plu)." ],
	['1', '-m', '--memory', "Memory (RAM) data. Physical system memory array(s), capacity, 
	how many devices (slots) supported, and individual memory devices 
	(sticks of memory etc). For devices, shows device locator, size, speed, 
	type (like: DDR3). If neither -I nor -tm are selected, also shows 
	ram used/total. Also see -x, -xx, -xxx" ],
	['1', '-M', '--machine', "Machine data. Device type (desktop, server, laptop, VM etc.), 
	Motherboard, Bios, and if present, System Builder (Like Lenovo). 
	Shows UEFI/BIOS/UEFI [Legacy]. Older systems/kernels without the 
	required /sys data can use dmidecode instead, run as root. 
	Dmidecode can be forced with -! 33" ],
	['1', '-n', '--network-advanced', "Advanced Network card information. Same as -Nn. Shows interface, 
	speed, mac id, state, etc." ],
	['1', '-N', '--network', "Network card information. With -x, shows PCI BusID, Port number." ],
	['1', '-o', '--unmounted', "Unmounted $partition_string information (includes UUID and 
	LABEL if available). Shows file system type if you have file installed, 
	if you are root OR if you have added to /etc/sudoers (sudo v. 1.7 or 
	newer) Example:^<username>^ALL^=^NOPASSWD:^/usr/bin/file^" ],
	['1', '-p', '--partitions-full', "Full $partition_string information (-P plus all other 
	detected ${partition_string}s)." ],
	['1', '-P', '--partitions', "Basic $partition_string information (shows what -v^4 would 
	show, but without extra data). Shows, if detected: 
	/ /boot /home /opt /tmp /usr /var /var/log /var/tmp . 
	Use -p to see all mounted ${partition_string}s." ],
	['1', '-r', '--repos', "Distro repository data. Supported repo types: APK; APT; PACMAN; 
	PISI; PORTAGE; PORTS (BSDs); SLACKPKG; URPMQ; YUM; ZYPP." ],
	['1', '-R', '--raid', "RAID data. Shows RAID devices, states, levels, and components, 
	and extra data with -x/-xx. md-raid: If device is resyncing, shows resync 
	progress line as well." ],
	['1', '-s', '--sensors', "Sensors output (if sensors installed/configured): mobo/cpu/gpu temp; 
	detected fan speeds. Gpu temp only for Fglrx/Nvidia drivers. Nvidia shows 
	screen number for > 1 screens." ],
	['1', '-S', '--system', "System information: host name, kernel, desktop environment 
	(if in X), distro" ],
	['1', '-t', '--processes', "Processes. Requires extra options: c^(cpu) m^(memory) cm^(cpu+memory). 
	If followed by numbers 1-20, shows that number of processes for each type 
	(default:^$ps_count; if in irc, max:^5): -t^cm10" ],
	['1', '', '', "Make sure to have no space between letters and numbers 
	(-t^cm10 - right, -t^cm^10 - wrong)." ],
	['1', '-u', '--uuid', "$partition_string_u UUIDs. Default: short $partition_string -P. 
	For full -p output, use: -pu (or -plu)." ],
	['1', '-v', '--verbosity', "Script verbosity levels. Verbosity level number is required. 
	Should not be used with -b or -F" ],
	['1', '', '', "Supported levels: 0-7 Example: $self_name^-v^4" ],
	['2', '0', '', "Short output, same as: $self_name" ],
	['2', '1', '', "Basic verbose, -S + basic CPU + -G + basic Disk + -I." ],
	['2', '2', '', "Networking card (-N), Machine (-M) data, if present, Battery (-B), 
	basic hard disk data (names only), and, if present, basic raid (devices only, 
	and if inactive, notes that). similar to: $self_name^-b" ],
	['2', '3', '', "Advanced CPU (-C), battery, network (-n) data, and switches on 
	-x advanced data option." ],
	['2', '4', '', "$partition_string_u size/filled data (-P) for (if present): /, 
	/home, /var/, /boot. Shows full disk data (-D)." ],
	['2', '5', '', "Audio card (-A); sensors^(-s), memory/ram^(-m), 
	$partition_string label^(-l) and UUID^(-u), short form of optical drives, 
	standard raid data (-R)." ],
	['2', '6', '', "Full $partition_string (-p), unmounted $partition_string (-o), 
	optical drive (-d), full raid; triggers -xx." ],
	['2', '7', '', "Network IP data (-i); triggers -xxx."]
	);
	push @data, @rows;
	# if distro maintainers don't want the weather feature disable it
	if ( $b_weather ){
		@rows = (
		['1', '-w', '--weather', "Local weather data/time. To check an alternate location, 
		see: -W^<location>. For extra weather data options see -x, -xx, and -xxx."],
		['1', '-W', '--weather-location', "<location> Supported options for <location>: postal code; 
		city, state/country; latitude, longitude. Only use if you want the weather 
		somewhere other than the machine running $self_name. Use only ascii 
		characters, replace spaces in city/state/country names with '+'. 
		Example:^$self_name^-W^new+york,ny"]
		);
		push @data, @rows;
	}
	@rows = (
	['1', '-x', '-extra', "Adds the following extra data (only works with verbose or line 
	output, not short form):" ],
	['2', '-B', '', "Vendor/model, status (if available)" ],
	['2', '-C', '', "CPU Flags, Bogomips on Cpu;CPU microarchitecture / revision if 
	found, like: (Sandy Bridge rev.2)" ],
	['2', '-d', '', "Extra optical drive data; adds rev version to optical drive." ],
	['2', '-D', '', "Hdd temp with disk data if you have hddtemp installed, if you are 
	root OR if you have added to /etc/sudoers (sudo v. 1.7 or newer) 
	Example:^<username>^ALL^=^NOPASSWD:^/usr/sbin/hddtemp" ],
	['2', '-G', '', "Direct rendering status for Graphics (in X)." ],
	['2', '-G', '', "(for single gpu, nvidia driver) screen number gpu is running on." ],
	['2', '-i', '', "For IPv6, show additional IP v6 scope addresses: Global, Site, 
	Temporary, Unknown." ],
	['2', '-I', '', "System GCC, default. With -xx, also show other installed 
	GCC versions. If running in console, not in IRC client, shows shell 
	version number, if detected. Init/RC Type and runlevel (if available)." ],
	['2', '-m', '', "Part number; Max memory module size (if available)." ],
	['2', '-N -A', '', "Version/port(s)/driver version (if available) for Network/Audio;" ],
	['2', '-N -A -G', '', "Network, audio, graphics, shows PCI Bus ID/Usb ID 
	number of card." ],
	['2', '-R', '', "md-raid: Shows component raid id. Adds second RAID Info line: 
	raid level; report on drives (like 5/5); blocks; chunk size; bitmap (if present). 
	Resync line, shows blocks synced/total blocks. zfs-raid:	Shows raid array 
	full size; available size; portion allocated to RAID" ],
	['2', '-S', '', "Desktop toolkit if available (GNOME/XFCE/KDE only); Kernel 
	gcc version" ],
	['2', '-t', '', "Memory use output to cpu (-xt c), and cpu use to memory (-xt m)." ]
	);
	push @data, @rows;
	if ( $b_weather eq 1 ){
		@rows = (['2', '-w -W', '', "Wind speed and time zone (-w only)." ]);
		push @data, @rows;
	}
	@rows = (
	['1', '-xx', '--extra 2', "Show extra, extra data (only works with verbose or line output, 
	not short form):" ],
	['2', '-A', '', "Chip vendor:product ID for each audio device." ],
	['2', '-B', '', "serial number, voltage (if available)." ],
	['2', '-C', '', "Minimum CPU speed, if available." ],
	['2', '-D', '', "Disk serial number; Firmware rev. if available." ],
	['2', '-G', '', "Chip vendor:product ID for each video card; (mir/wayland only) 
	compositor (alpha test); OpenGL compatibility version, if free drivers and 
	available." ],
	['2', '-I', '', "Other detected installed gcc versions (if present). System 
	default runlevel. Adds parent program (or tty) for shell info if not in IRC
	(like Konsole or Gterm). Adds Init/RC (if found) version number." ],
	['2', '-m', '', "Manufacturer, Serial Number, single/double bank (if found)." ],
	['2', '-M', '', "Chassis information, bios rom size (dmidecode only), if data for 
	either is available." ],
	['2', '-N', '', "Chip vendor:product ID for each nic." ],
	['2', '-R', '', "md-raid: Superblock (if present); algorythm, U data. Adds 
	system info line (kernel support,read ahead, raid events). If present, 
	adds unused device line. Resync line, shows progress bar." ],
	['2', '-S', '', "Display manager (dm) in desktop output, if in X 
	(like kdm, gdm3, lightdm)." ],
	);
	push @data, @rows;
	if ( $b_weather ){
		@rows = (['2', '-w -W', '', "Humidity, barometric pressure." ]);
		push @data, @rows;
	}
	@rows = (
	['1', '-xxx', '--extra 3', "Show extra, extra, extra data (only works with verbose or 
	line output, not short form):" ],
	['2', '-B', '', "chemistry, cycles, location (if available)." ],
	['2', '-m', '', "Width of memory bus, data and total (if present and greater 
	than data); Detail, if present, for Type; module voltage, if available." ],
	['2', '-S', '', "Panel/shell information in desktop output, if in X 
	(like gnome-shell, cinnamon, mate-panel)." ]
	);
	push @data, @rows;
	if ( $b_weather ){
		@rows = (['2', '-w -W', '', "Location (uses -z/irc filter), weather 
		observation time, wind chill, heat index, dew point (shows extra lines 
		for data where relevant)." ] );
		push @data, @rows;
	}
	@rows = (
	['1', '-y', '--width', "Required extra option: integer, 80 or greater. Set the output 
	line width max. Overrides IRC/Terminal settings or actual widths. If used 
	with -h, put -y option first. Example:^inxi^-y^130" ],
	['1', '-z', '--filter', "Security filters for IP/Mac addresses, location, user home 
	directory name. Default on for irc clients." ],
	['1', '-Z', '--filter-override', "Absolute override for output filters. Useful for debugging 
	networking issues in irc for example." ],
	[0, '', '', "$line" ],
	[0, '', '', "Additional Options:" ],
	['1', '-h', '--help', "This help menu." ],
	['1', '-H', '--help-full', "This help menu, plus developer options. Do not use dev options in 
	normal operation!" ],
	['1', '', '--recommends', "Checks $self_name application dependencies + recommends, 
	and directories, then shows what package(s) you need to install to add support 
	for that feature. " ]
	);
	push @data, @rows;
	if ( $b_update ){
		@rows = (
		['1', '-U', '--update', "Auto-update script. Will also install/update man page. 
		Note: if you installed as root, you must be root to update, otherwise user 
		is fine. Man page installs require root user mode. No arguments downloads from main 
		$self_name git repo." ],
		['1', '', '', "Use alternate sources for updating $self_name" ],
		
		['2', '1', '', "Get the git branch one version." ],
		['2', '2', '', "Get the git branch two version." ],
		['2', '<http>', '', "Get a version of $self_name from your own server if you want, 
		put the full download path, like: $self_name -U https://myserver.com/inxi" ]
		);
		push @data, @rows;
		
	}
	@rows = (
	['1', '-V', '--version', "$self_name version information. Prints information 
	then exits." ],
	[0, '', '', "$line" ],
	[0, '', '', "Debugging Options:" ],
	
	['1', '', '--debug', "Triggers debugging modes." ],
	['2', '1-3', '', "On screen $self_name debugger output" ],
	['2', '10', '', "Basic $self_name logging." ],
	['2', '11', '', "Full file/system info logging" ],
	['2', '12', '', "Plus Color logging." ],
	['1', '', ,'', "The following create a tar.gz file of system data, plus collecting 
	the inxi output to file. To automatically upload debugger data tar.gz file 
	to ftp.techpatterns.com: inxi^--debug^21" ],
	['2', '20', '', "Full system data collection: /sys; xorg conf and 
	log data, xrandr, xprop, xdpyinfo, glxinfo etc.; data from dev, disks, 
	${partition_string}s, etc." ],
	['2', '21', '', "Upload debugger dataset to $self_name debugger server 
	automatically." ],
	['1', '', '--ftp', "Use with --debugger 21 to trigger an alternate FTP server for upload. 
	Format:^[ftp.xx.xx/yy]. Must include a remote directory to upload to: 
	Example:^ftp.myserver.com/incoming" ],
	[0, '', '', "$line" ],
	[0, '', '', "Advanced Options:" ],
	[1, '', '--alt', "Trigger for various advanced options:" ],
	['2', '0', '', "Overrides defective or corrupted data." ],
	['2', '31', '', "Turns off hostname in output. Useful if showing output from 
	servers etc." ],
	['2', '32', '', "Turns on hostname in output. Overrides global \$b_host'" ],
	['2', '33', '', "Forces use of dmidecode data instead of /sys where 
	relevant (-M)." ],
	['2', '34', '', "Skips SSL certificate checks for all downloader activies 
	(wget/fetch/curl only). Must go before other options." ],
	['2', '40', '', "Bypass Perl as a downloader option." ],
	['2', '41', '', "Bypass Curl as a downloader option." ],
	['2', '42', '', "Bypass Fetch as a downloader option." ],
	['2', '43', '', "Bypass Wget as a downloader option." ],
	['2', '44', '', "Bypass Curl, Fetch, and Wget as a downloader options. Forces 
	Perl if HTTP::Tiny present." ],
	['1', '', '--display', "Will try to get display data out of X. Default gets it from display 0. 
	If you use this format: ---display 1 it would get it from display 1 instead, or any 
	display you specify" ],
	['1', '', '--downloader', "Force $self_name to use [curl|fetch|perl|wget] for downloads." ],
	['0', '', '', $line ]
	);
	push @data, @rows;
	if ( $type eq 'full' ){
		@rows = (
		[0, '', '', "Developer and Testing Options (Advanced):" ],
		['1', '', '--alt', "Trigger for dev/test options:" ],
		['2', '1', '', "Sets testing flag test1=1 to trigger 
		testing condition 1." ],
		['2', '2', '', "Sets testing flag test2=1 to trigger 
		testing condition 2." ],
		['2', '3', '', "Sets flags test3=1." ],
		['0', '', '', $line ]
		);
		push @data, @rows;
	}
	print_basic(@data); 
}
