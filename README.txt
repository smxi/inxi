====================================================================
README for development branch of inxi Perl version: pinxi
====================================================================
FILE:    README.txt
VERSION: 1.3
DATE:    2017-12-11

NOTE: While the real program name will never change, for the sake
of clarity, I will refer to the inxi-perl dev branch inxi as pinxi, 
and bash/gawk master branch inxi as binxi in the following.

During development, so I can more easily test changes, the name is 
changed on the file and internally to pinxi until it is ready  for 
release in master branch.

====================================================================

Clone just this branch:

git clone https://github.com/smxi/inxi --branch inxi-perl --single-branch

====================================================================

DOCS:

/docs contain the data I use to develop pinxi. it's what I need to
know to rewrite binxi to pinxi, that is.

See: docs/perl-programming.txt
Tips and hints on how to translate other language logic to Perl, and 
Bash stuff in particular. Note, I will never be a Perl expert, nor do 
I want to be. I want the code to be 'newbie' friendly, and to be accessible
to reasonably smart people who do not happen to be Perl experts, but do 
understand basic programming logic. 

Perl was selected because it will be easier to work with than the 
bash/gawk/sed/grep/etc mix that currently runs binxi, and because 
the 5.x branch has proved itself to be very solid over years, 
without breaking stuff needlessly on updates. It was not selected 
because I like it. In a way, it was a blessing that Larry made Perl6, 
and now calls it a different language, because that removed  the 
pressure from Perl 5 to break itself. While I will use internally 
Perl 'write only' methods where it really is a good way to do it, 
I will try to minimize that style as much as possible in order to leave
pinxi code reasonably accessible to most competent people who can 
read code ok, but who are not Perl experts.

See: docs/perl-setup.txt
How to set up your Perl dev stuff

See: docs/perl-version-support.txt
Notes on what features can be used for the perl version. 5.08 is the current 
cutoff. No newer features will be used, this lets me maintain the core inxi 
mission of supporting almost everything, no matter how old.

See: docs/inxi-values.txt
User config options; the values of the primary hashes that contain the 
switches used for layout, option control, downloader, konvi etc. 
Those have been removed from the top variable assignments of binxi 
to make the code clear and easy to read, and to avoid the clutter binxi 
suffers from. inxi-values.txt is the primary reference document for 
working on pinxi.

====================================================================

BASIC IDEA:

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

Also, with the proper setup, inxi perl may be developed in discreet 
modules, which would be combined to form the final inxi prior to 
commit. Or at least to make it easier to work on one piece at a time.

====================================================================

ROADMAP:

Note that my current development goals are, roughly in this order:

1. Complete startup/initialization code. This is going well.

2. Complete debug logging code. This is done.

3. Complete debugger data collector. 

4. Complete recommends output. This will wait for longer down the
   road when I actually know what the recommends are.
   
5. Complete option handler. This is almost done, I'm just waiting
   to decide on the last option names etc. Slow but sure.
   
6. Complete help/version output handlers. This depends on at least
   a basic output printer logic working.
   
7. Complete startup logic, that's what gets irc client info, etc.
   That will be difficult because it's difficult logic.
   
8. Complete line printers and colorizers. This will probably be done
   in 2 parts: 
   1. for no colorized, sized, indentation controlled: -h or -V
   2. full, hash print out, colorizer, sizer. real inxi output.
   
9. Start on get data and print lines, which is about 1/2 the program.
   This will probably start by line data collection, then move to a
   radically altered print handler, which I expect to be far far 
   more simple than the binxi version has.
   To keep this sane, I'll probably work on .pm files that contain the
   data collection logic per line, or feature, I'll see. Shared logic
   will go in the:
   SPECIAL DATA HANDLERS - UTILITIES FOR GET DATA/PRINT LINES
   section.
   
10. Look into adding support for language hashes, that would replace 
the hack key values in the print arrays with the alternate language 
equivalent. Or, if missing that key, print the english. That would
solve the issue of people flaking out on language support over time.

11. Related to 10, add support for alternate output formats, using 
json or csv or xml. I assume Perl has modules that make that easy, but 
it's not very hard to do that manually either once you have the line
data in hashes.

====================================================================

HELP? MAYBE LATER

So I may experiment with this a bit, it also depends on if I can
generate any interest, since there's no practical way I can actually
refactor inxi by myself into perl, it's too much work, even though
the gawk blocks are largely directly translatable to Perl.

However, I feel fairly certain that due to the very specific logic
of binxi, the only real way to translate the stuff is to create the
logic engines, init, startup, print, debug, log, before the actual 
data or printer features can be rolled out, though I'll probably do
some basic printer stuff just to get the rough logic worked out.

But what I see is rewriting the init, startup, debug, log, and print
logic first before I'll really deal with any possible help, because
it's all so specific and hard to understand, that it's unlikely 
anyone will. Unless I'm lucky.

Now, if you are willing and able to do literal function translations
from the existing Bash/Gawk/Sed/tr/wc/grep/etc in binxi to the Perl
equivalents in pinxi, and are most important, willing to accept that
almost every line of logic in binxi is there to handle real events 
that have happened and which the logic has seen, which means, it 
does very little good to skip stuff you don't think matters, or that
you don't understand, etc, it's all got to be translated, every bit,
well, then, I really would welcome your help. As long as you are not
interested in creating write only Perl code, which would be the long
term death knell for pinxi as a project. Be verbose!!! Celebrate!!
Use 3 lines where one could do it!! Separate conditions from
statements and actions!! You can do it!! I believe in you!! Be nice
to the future, not mean.

