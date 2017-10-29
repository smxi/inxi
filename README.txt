README for heavily experimental inxi Perl version.

=====================================================================
Whether we ever make any progress on this is a totally open question,
but I was sufficiently impressed switching from xiin python script
to creating two small perl functions to do the primary /sys debugging
actions that Perl for inxi struck me as an increasingly interessting
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

Also, with the proper setup, inxi perl could be developed in discreet 
modules, which would be combined to form the final inxi prior to 
commit.

So I may experiment with this a bit, it also depends on if I can
generate any interest, since there's no practical way I can actually
refactor inxi by myself into perl, it's too much work, even though
the gawk blocks are largely directly translatable to Perl.

But this branch will be the home for perl related inxi development.

=====================================================================
