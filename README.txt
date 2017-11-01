README for heavily experimental inxi Perl version.

=====================================================================
Whether we ever make any progress on this is a totally open question,
but I was sufficiently impressed switching from xiin python script
to creating two small perl functions to do the primary /sys debugging
actions that Perl for inxi struck me as an increasingly interesting
idea. Plus, Perl was so comically, absurdly, fast, that I could not
ignore it.

Another big reason this is being given real thought is that while 
an absolutely core, primary, requirement, for inxi, is that it run
anywhere, on any nix system, no matter how old (practially speaking,
10 years old or newer), that is, you can pop inxi on an old server
and it will work. Bash + Gawk will always, and has always, met that
requirement, but that combination, with the lack of any real way
to pass data, create complex arrays, etc, has always been a huge 
headache to work with.

However, unlike in 2007, when the basic logic of inxi was started,
and Perl 6 was looming as a full replacement for Perl 5, in 2017, 
Perl 5 is now a standalone project, and seems to have a bright 
future, and given that 5.8 is now old enough to satisfy the basic
run anywhere on anything option, that would be the basic perl version
that would be used and tested against. I've vacillated a bit between
5.10 and 5.8, but after more research, I've realized there will 
always be old Redhat servers etc out there that are running Perl 5.8,
and there is not a huge gain to using 5.10 from what I can see.

Also, with the proper setup, inxi perl could be developed in discreet 
modules, which would be combined to form the final inxi prior to 
commit.

So I may experiment with this a bit, it also depends on if I can
generate any interest, since there's no practical way I can actually
refactor inxi by myself into perl, it's too much work, even though
the gawk blocks are largely directly translatable to Perl.

But this branch will be the home for perl related inxi development.

=====================================================================

Clone just this branch:

git clone https://github.com/smxi/inxi --branch inxi-perl --single-branch
