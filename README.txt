====================================================================
README for development branch of inxi Perl version: pinxi
====================================================================
FILE:    README.txt
VERSION: 2.5
DATE:    2018-02-16

NOTE: While the real program name will never change, for the sake
of clarity, I will refer to the inxi-perl dev branch inxi as pinxi, 
and bash/gawk master branch inxi as binxi in the following.

During development, so I can more easily test changes, the name is 
changed on the file and internally to pinxi until it is ready  for 
release in master branch.

====================================================================

Clone just this branch:

git clone https://github.com/smxi/inxi --branch inxi-Perl --single-branch

Install pinxi for testing. Note that the -U option works now so 
only the initial install is required:

wget -O pinxi https://github.com/smxi/inxi/raw/inxi-perl/pinxi

====================================================================

DOCS:

/docs contain the data I use to develop pinxi. it's what I need to
know to rewrite binxi to pinxi, that is.

See: docs/Perl-programming.txt
Tips and hints on how to translate other language logic to Perl, and 
Bash stuff in particular. Note, I will never be a Perl expert, nor do 
I want to be. I want the code to be 'newbie' friendly, and to be accessible
to reasonably smart people who do not happen to be Perl experts, but do 
understand basic programming logic. 

Perl was selected because it will be easier to work with than the 
bash/gawk/sed/grep/etc mix that currently runs binxi, and because 
the 5.x branch has proved itself to be very solid over years, 
without breaking stuff needlessly on updates. In a way, it was a 
blessing that Larry made Perl6, and now calls it a different language, 
because that removed  the pressure from Perl 5 to break itself. 

See: docs/Perl-setup.txt
How to set up your Perl dev stuff

See: docs/Perl-version-support.txt
Notes on what features can be used for the Perl version. 5.08 is the current 
cutoff. No newer features will be used, this lets me maintain the core inxi 
mission of supporting almost everything, no matter how old.

See: docs/inxi-tools.txt
Core tools available for features and modules. Since most log their 
data, it's always preferable using a core tool that to recode it again.
With some exceptions, for example, extreme repetitions where you want
to remove any possible overhead in the action, like parsing 1000 lines.

See: docs/inxi-values.txt
User config options; the values of the primary hashes that contain the 
switches used for layout, option control, downloader, konvi etc. 
Those have been removed from the top variable assignments of binxi 
to make the code clear and easy to read, and to avoid the clutter binxi 
suffers from. inxi-values.txt is the primary reference document for 
working on pinxi.

====================================================================

BASIC IDEA:

I was sufficiently impressed switching from xiin python script
to creating two small Perl functions to do the primary /sys debugging
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
run anywhere on anything option, that would be the basic Perl version
that would be used and tested against. I've vacillated a bit between
5.10 and 5.8, but after more research, I've realized there will 
always be old Redhat servers etc out there that are running Perl 5.8,
and there is not a huge gain to using 5.10 from what I can see.

This is being tested during development on systems that run 5.08, 5.10,
5.12, and of course, modern Perl 5.26 as of current. So yes, there are
plenty of old servers and systems out there still running Perl 5.08.

Also, with the proper setup, inxi Perl may be developed in discreet 
modules, which would be combined to form the final inxi prior to 
commit. Or at least to make it easier to work on one piece at a time.

====================================================================

ROADMAP:

Note that my current development goals are, roughly in this order:

1. Complete startup/initialization code. 
   Status: DONE

2. Complete debug logging code. 
   Status: DONE

3. Complete debugger data collector. 
   Status: DONE

4. Complete recommends output. This is OS aware, and only offers BSDs
   and GNU/Linux systems the appropriate files/directories/programs.
   Status: DONE
   
5. Complete option handler. 
   Status: DONE.
   
6. Complete help/version output handlers. 
   Status: DONE
   
7. Complete startup client logic, that's what gets irc client info, etc.
   Status: DONE
   
8. Complete line printers and colorizers. 
   1. for no colorized, sized, indentation controlled: -h or -V
      Status: DONE
   2. full, hash print out, colorizer, sizer. real inxi output.
      Status: DONE
   
9. Start on get data and print lines, which is about 2/3 the program.
   
   Status of Lines:
     Short: 
     ALMOST DONE: 
     missing Disk Basic
     
     Basic -b:
     ALMOST DONE: 
     missing Disk Basic
     
     Full:
     System: DONE
     Machine: DONE
     Battery: DONE
     Memory: DONE
     PCI Slots: DONE: NEW!
     CPU: DONE
     Graphics: DONE
     Audio: DONE 
     Network: DONE - with new features!
     Drives: Started - stub
     Optical: Not started
     Partition: Started  - stub
     RAID: Started - stub 
     Unmounted: Started - stub 
     USB Info: DONE: NEW!
     Sensors: Started
     Repos: DONE
     Processes: DONE - Improved significantly
     Weather: DONE
     Info: DONE
     
10. Man page. Not Started, waiting til feature complete more or less.

11. Look into adding support for language hashes, that would replace 
    the hack key values in the print arrays with the alternate language 
    equivalent. Or, if missing that key, print the english. That would
    solve the issue of people flaking out on language support over time.
    Status: NOT Started (but support is designed in as I go along)

12. Related to 10, add support for alternate output formats, using 
    json or csv or xml. I assume Perl has modules that make that easy, but 
    it's not very hard to do that manually either once you have the line
    data in hashes.
    Status: Started (Support built in as I go along, only the actual 
    output engines will need to be created.)

====================================================================

HELP? BSD Welcome!!

So I may experiment with this a bit, it also depends on if I can
generate any interest, since there's no practical way I can actually
refactor inxi by myself into Perl, it's too much work, even though
the gawk blocks are largely directly translatable to Perl.

However, due to the very specific logic of binxi, the only real way 
to translate the stuff was to create the logic engines, init, startup, 
print, debug, log, before the actual data or printer features could be 
rolled out.

Now, if you are willing and able to do literal function translations
from the existing Bash/Gawk/Sed/tr/wc/grep/etc in binxi to the Perl
equivalents in pinxi, and are most important, willing to accept that
almost every line of logic in binxi is there to handle real events 
that have happened and which the logic has seen, which means, it 
does very little good to skip stuff you don't think matters, or that
you don't understand, etc, it's all got to be translated, every bit,
well, then, I really would welcome your help. 

BSD?
I need help on all BSD functions and tools. Those will be obvious as
I go along, tools that have specific modules for Linux or BSD will
be added to modules/ as I go along, and I will just leave the BSD
stub sub, and the data structure will be obvious from the Linux
version.

