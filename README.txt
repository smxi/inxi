README for inxi - a command line system information tool

The new faster, more powerful Perl inxi is here! File all issue reports with the 
master branch. All support for versions prior to 3.0 is now ended, sorry. 

Make sure to update to the current inxi from the master branch before filing any 
issue reports. The code in pre 2.9 versions literally no longer exists in inxi 
3. Bugs from earlier versions cannot usually be solved in the new version since 
the pre 2.9 and the 2.9 and later versions are completely different internally.

--------------------------------------------------------------------------------
CODEBERG SOURCE REPO
--------------------------------------------------------------------------------

Packagers: Make sure to change your package URLs and repos to use codeberg.org.

The previous inxi-perl, tarballs, and docs branches are now standalone repos
on codeberg.org:

docs      > https://codeberg.org/smxi/inxi-docs master
inxi-perl > https://codeberg.org/smxi/pinxi master
master    > https://codeberg.org/smxi/inxi master
tarballs  > https://codeberg.org/smxi/inxi-tarballs master

inxi-perl has been rebuilt and now only contains the pinxi, pinxi.1 files, plus
a minimal README.txt for github users. docs and tarballs have been deleted. The
inxi-perl branch should not be used, and exists only so that current pinxi users 
can update from there to get the new version with new URLs.

inxi master and inxi-perl/pinxi will be mirrored until late 2023, then they will
no longer get updates.

The inxi repo only contains master, plus the one, two branches, which are 
obsolete. 

--------------------------------------------------------------------------------

Please file issue reports or feature requests at:

https://codeberg.org/smxi/inxi

Please take the time to read this helpful article from the Software Freedom
Conservancy:

https://sfconservancy.org/GiveUpGitHub/

Any use of this project's code by GitHub Copilot, past or present, is done 
without my permission. I do not consent to GitHub's use of this project's code 
in Copilot.

--------------------------------------------------------------------------------
DONATE
--------------------------------------------------------------------------------

Help support the project with a one time or a sustaining donation.

Paypal: https://www.paypal.com/donate/?hosted_button_id=77DQVM6A4L5E2

LiberaPay (sustaining donations): https://liberapay.com/smxi/

================================================================================
DEVELOPMENT AND ISSUES
--------------------------------------------------------------------------------

Make inxi better! Expand supported hardware and OS data, fix broken items!

--------------------------------------------------------------------------------
HELP PROJECT DEVELOPMENT! SUBMIT A DEBUGGER DATASET
--------------------------------------------------------------------------------

This is easy to do, and only takes a few seconds. These datasets really help the 
project add and debug features. You will generally also be asked to provide this 
data for non trivial issue reports.

Note that the following options are present:

1. Generate local gz'ed debugger dataset. Leaves gz on your system:
 inxi version >= 3: inxi --debug 20 
2. Generate, upload gz'ed debugger dataset. Leaves gz on your system:
 inxi version >= 3: inxi --debug 21
3. Generate, upload, delete gz'ed debugger dataset:
 inxi version >= 3: inxi --debug 22

You can run these as regular user, or root/sudo, which will gather a bit more 
data, like from dmidecode, and other tools that need superuser permissions to 
run.

ARM (plus MIPS, SPARC, PowerPC) and BSD datasets are particularly appreciated 
because we simply do not have enough of those.

--------------------------------------------------------------------------------
FILE AN ISSUE IF YOU FIND SOMETHING MISSING, BROKEN, OR FOR AN ENHANCEMENT
--------------------------------------------------------------------------------

inxi strives to support the widest range of operating systems and hardware, from 
the most simple consumer desktops, to the most advanced professional hardware 
and servers. 

The issues you post help maintain or expand that support, and are always 
appreciated since user data and feedback is what keeps inxi working and 
supporting the latest (or not so latest) hardware and operating systems. 

See INXI VERSION/SUPPORT/ISSUES/BUGS INFORMATION for more about issues/support.

See BSD/UNIX below for qualifications re BSDs, and OSX in particular. 

================================================================================
SOURCE VERSION CONTROL
--------------------------------------------------------------------------------

inxi:
REPO: https://codeberg.org/smxi/inxi
MAIN BRANCH: master
DEVELOPMENT BRANCHES [not used]: one, two

pinxi [development version for inxi]:
REPO: https://codeberg.org/smxi/pinxi
MAIN BRANCH: master

pinxi is the standalone development version of inxi. inxi branches one, two are 
rarely if ever used. inxi has the built in feature to be able to update itself 
from anywhere, including these branches, which is very useful for development 
and debugging on various user systems.

Please: NEVER even think about looking at or using previous inxi commits, 
previous to the current master version, as a base for a patch. If you do, your 
patch / pull request will probably be rejected.

PULL REQUESTS: Please talk to me before starting to work on patches of any 
reasonable complexity. inxi is hard to work on, and you have to understand how 
it works before submitting patches, unless it's a trivial bug fix. Never work 
with inxi master, always work with pinxi master, since it can be quite far ahead 
of inxi. inxi master has only one purpose, to get updated to next inxi when 
pinxi is ready to be copied over to inxi. pinxi is always equal to or ahead of 
master branch inxi.

Man page updates, doc pages updates, etc, of course, are easy and will probably 
be accepted, as long as they are properly formatted and logically coherent. 

When under active development, pinxi releases early, and releases often. inxi
is stable and is generally only updated when a new tagged version is completed.

PACKAGERS: inxi has one and only one 'release', and that is the current tagged 
version in the master branch (plus pinxi repo, of course, but pinxi should in 
general not be packaged). 

--------------------------------------------------------------------------------
MASTER BRANCH
--------------------------------------------------------------------------------

This is the only supported branch, and the current latest commit/version is the 
only supported 'release'. There are no 'releases' of inxi beyond the current 
commit/version in master. All past versions are not supported. 

git clone https://codeberg.org/smxi/inxi --branch master --single-branch

OR direct fast and easy install:

wget -O inxi https://codeberg.org/smxi/inxi/raw/master/inxi

OR easy to remember shortcut (which redirects to codeberg.org):

wget -O inxi https://smxi.org/inxi
wget -O inxi smxi.org/inxi

NOTE: There are no 'Releases' per se. There are only tagged commits, period. A 
tag is a pointer to a commit, and has no further meaning. A tagged commit 
however is the target for packagers.

If your distribution has blocked -U self updater and you want a newer version:

Open /etc/inxi.conf and change false to true: B_ALLOW_UPDATE=true

--------------------------------------------------------------------------------

SPECIAL NOTE FOR LEGACY OPERATING SYSTEMS WITH NO TLS 1.2 OR GREATER: Modern web 
servers are dropping support for TLS 1.0, 1.1, and so has smxi.org, this means 
to install inxi onto an older system with only TLS 1.0 or 1.1 available, you 
will need to do this to install inxi onto the old system:

wget -O /usr/local/bin/inxi ftp://ftp.smxi.org/outgoing/inxi

then update inxi/man pages after that with inxi -U 4, which uses FTP, not HTTP,
to download the file.

For pinxi, just change inxi to pinxi above (add --man to get the man page), and 
it will work the same.

--------------------------------------------------------------------------------
DEVELOPMENT VERSION (in pinxi repo)
--------------------------------------------------------------------------------

All active development is done in the pinxi repo master branch.:

git clone https://codeberg.org/smxi/pinxi

OR direct fast and easy install:

wget -O pinxi https://codeberg.org/smxi/pinxi/raw/master/pinxi

OR easy to remember shortcut (which redirects to codeberg.org):

wget -O pinxi https://smxi.org/pinxi
wget -O pinxi smxi.org/pinxi

Once new features have been debugged, tested, and are reasonably stable, pinxi 
is copied to inxi in the inxi master branch.

It's a good idea to check with pinxi if you want to make sure your issue has not 
been corrected, since pinxi is always equal to or ahead of inxi.

See SPECIAL NOTE FOR LEGACY OPERATING SYSTEMS above to install pinxi on very old 
operating systems with out of date TLS version.

--------------------------------------------------------------------------------
LEGACY INXI (in inxi-legacy repo)
--------------------------------------------------------------------------------

If you'd like to look at the Gawk/Bash version of inxi, you can find it in the 
inxi-legacy repo, as binxi in the /inxi-legacy directory:

Direct fast and easy install:

wget -O binxi https://codeberg.org/smxi/inxi-legacy/raw/master/binxi

OR easy to remember shortcut (which redirects to codeberg.org):

wget -O binxi https://smxi.org/binxi

This version will not be maintained, and it's unlikely that any time will be 
spent on it in the future, but it is there in case it's of use or interest to 
anyone.

This was kept for a long time as the inxi-legacy branch of inxi, but was moved 
to the inxi-legacy repo 2021-09-24.

================================================================================
SUPPORT INFO
--------------------------------------------------------------------------------

Do not ask for basic help that reading the inxi -h / --help menus, or man page 
would show you, and do not ask for features to be added that inxi already has. 
Also do not ask for support if your distro won't update its inxi version, some 
are bad about that.

--------------------------------------------------------------------------------
DOCUMENTATION
--------------------------------------------------------------------------------

https://smxi.org/docs/inxi.htm 
(smxi.org/docs/ is easier to remember, and is one click away from inxi.htm). The 
one page wiki on codeberg.org is only a pointer to the real resources.

https://codeberg.org/smxi/pinxi/src/branch/master/docs

Contains specific Perl inxi documentation, of interest mostly to developers. 
Includes internal inxi tools, values, configuration items. Also has useful 
information about Perl version support, including the list of Core modules that 
_should_ be included in a distribution's core modules, but which are 
unfortunately sometimes removed. 

INXI CONFIGURATION: https://smxi.org/docs/inxi-configuration.htm 
HTML MAN PAGE: https://smxi.org/docs/inxi-man.htm 
INXI OPTIONS PAGE: https://smxi.org/docs/inxi-options.htm 

NOTE: Check the inxi version number on each doc page to see which version will 
support the options listed. The man and options page also link to a legacy 
version, pre 2.9.

https://codeberg.org/smxi/inxi/wiki

This is simply a page with links to actual inxi resources, which can be useful 
for developers and people with technical questions. No attempt will be made to 
reproduce those external resources on codeberg.org. You'll find stuff like 
how to export to json/xml there, and basic core philosophies, etc. 

--------------------------------------------------------------------------------
IRC
--------------------------------------------------------------------------------

You can go to: 

irc.oftc.net or irc.libera.chat channel #smxi 

but be prepared to wait around for a while to get a response. Generally it's 
better to use codeberg.org issues.

--------------------------------------------------------------------------------
ISSUES
--------------------------------------------------------------------------------

https://codeberg.org/smxi/inxi/issues

No issues accepted for non current inxi versions. See below for more on that. 
Unfortunately as of 2.9, no support or issues can be accepted for older inxi's 
because inxi 2.9 (Perl) and newer is a full rewrite, and legacy inxi is not 
being supported since our time here on earth is finite (plus of course, one 
reason for the rewrite was to never have to work with Gawk->Bash again!).

Sys Admin type inxi users always get the first level of support. ie, convince us 
you run real systems and networks, and your issue shoots to the top of the line. 
As do any real bugs. 

Failure to supply requested debugger data will lead To a distinct lack of 
interest on our part to help you with a bug. ie, saying, oh, it doesn't work, 
doesn't cut it, unless it's obvious why. 

--------------------------------------------------------------------------------
SUPPORT FORUMS
--------------------------------------------------------------------------------

https://techpatterns.com/forums/forum-33.html
This is the best place to place support issues that may be complicated.

If you are developer, use:
DEVELOPER FORUMS: https://techpatterns.com/forums/forum-32.html

================================================================================
ABOUT INXI
--------------------------------------------------------------------------------

inxi is a command line system information tool. It was forked from the ancient 
and mindbendingly perverse yet ingenius infobash, by locsmif. 

That was a buggy, impossible to update or maintain piece of software, so the 
fork fixed those core issues, and made it flexible enough to expand the utility 
of the original ideas. Locmsif has given his thumbs up to inxi, so don't be 
fooled by legacy infobash stuff you may see out there.

inxi is lower case, except when I create a text header here in a file like this, 
but it's always lower case. Sometimes to follow convention I will use upper case 
inxi to start a sentence, but i find it a bad idea since invariably, someone 
will repeat that and type it in as the command name, then someone will copy 
that, and complain that the command: Inxi doesn't exist...

The primary purpose of inxi is for support, and sys admin use. inxi is used 
widely for forum and IRC support, which is I believe it's most common function.

If you are piping output to paste or post (or writing to file), inxi now 
automatically turns off color codes, so the inxi 2.3.xx and older suggestion to 
use -c 0 to turn off colors is no longer required.

inxi strives to be as accurate as possible, but some things, like memory/ram 
data, depend on radically unreliable system self reporting based on OEM filling 
out data correctly, which doesn't often happen, so in those cases, you want to 
confirm things like ram capacity with a reputable hardware source, like 
crucial.com, which has the best ram hardware tool I know of.

--------------------------------------------------------------------------------
COMMITMENT TO LONG TERM STABILITY
--------------------------------------------------------------------------------

The core mission of inxi is to always work on all systems all the time. Well, 
all systems with the core tools inxi requires to operate installed. 

What this means is this: you can have a 10 year old box, or probably 15, not 
sure, and you can install today's inxi on it, and it will run. It won't run 
fast, but it will run. I test inxi on a 200 MHz laptop from about 1998 to keep 
it honest. That's also what was used to optimize the code at some points, since 
differences appear as seconds, not 10ths or 100ths of seconds on old systems 
like that.

inxi is being written, and tested, on Perl as old as 5.08, and will work on any 
system that runs Perl 5.08 or later. Pre 2.9.0 Gawk/Bash inxi will also run on 
any system no matter how old, within reason, so there should be no difference.

--------------------------------------------------------------------------------
FEATURES AND FUNCTIONALITY
--------------------------------------------------------------------------------

inxi's functionality continues to grow over time, but it's also important to 
understand that each core new feature usually requires about 30 days work to get 
it stable. So new features are not trivial things, nor is it acceptable to 
submit a patch that works only on your personal system. 

One inxi feature (-s, sensors data), took about 2 hours to get working in the 
alpha test on the local dev system, but then to handle the massive chaos that is 
actual user sensors output and system variations, it took several rewrites and 
about 30 days to get somewhat reliable for about 98% or so of inxi users. So if 
your patch is rejected, it's likely because you have not thought it through 
adequately, have not done adequate testing cross system and platform, etc.

--------------------------------------------------------------------------------
SUPPORTED VERSIONS / DISTRO VERSIONS
--------------------------------------------------------------------------------

Important: the only version of inxi that is supported is the latest current 
master branch version/commit. No issue reports or bug reports will be accepted 
for anything other than current master branch. No merges, attempts to patch old 
code from old versions, will be considered or accepted on the master branch of 
inxi. If you are not updated to the latest inxi, do not file a bug report since 
it's probably been fixed ages ago. If your distro isn't packaging a current 
inxi, then file a bug report with your packager, not here. 

The development branch inxi-perl/pinxi  has been moved to its own standalone 
repo, pinxi, at https://codeberg.org/smxi/pinxi - this is the only place 
development happens.

inxi is 'rolling release' software, just like Debian Sid, Gentoo, or Arch Linux 
are rolling release GNU/Linux distributions, with no 'release points'.

Distributions should never feel any advantage comes from using old inxi versions 
because inxi has as a core promise to you, the end user, that it will never 
require new tools to run. New tools may be required for a new feature, but that 
will always be handled internally by inxi, and will not cause any operational 
failures. This is a promise, and I will never as long as I run this project 
violate that core inxi requirement. Old inxi is NOT more stable than current 
inxi, it's just old, and lacking in bug fixes and features. For pre 2.9 
versions, it's also significantly slower, and with fewer features.

Your distro not updating inxi ever, then failing to show something that is fixed 
in current inxi is not a bug, and please do not post it here. File the issue 
with your distro, not here. Updating inxi in a package pool will NEVER make 
anything break or fail, period. It has no version based dependencies, just 
software, like Perl 5.xx, lspci, etc. There is never a valid reason to not 
update inxi in a package pool of any distro in the world (with one single known 
exception, the Slackware based Puppy Linux release, which ships without the full 
Perl language. The Debian based one works fine).

--------------------------------------------------------------------------------
SEMANTIC VERSION NUMBERING
--------------------------------------------------------------------------------

inxi uses 'semantic' version numbering, where the version numbers actually mean 
something.

The version number follows these guidelines:

Using example 3.2.28-6

The first digit(s), "3", is a major version, and almost never changes. Only a 
huge milestone, or if inxi reaches 3.9.xx, when it will simply move up to 4.0.0 
just to keep it clean, would cause a change. 

The second digit(s), "2", means a new real feature has been added. Not a tweaked 
existing feature, an actual new feature, which usually also has a new argument 
option letter attached. The second number goes from 0 to 9, and then rolls over 
the first after 9. 

The third, "28", is for everything not covered by 1 and 2, can cover bug fixes, 
tweaks to existing features to add support for something, full on refactors of 
existing features, pretty much anything where you want the end user to know that 
they are not up to date. The third goes from 0 to 99, then rolls over the 
second.

The fourth, "6", is extra information about certain types of inxi updates. I 
don't usually use this last one in master branch, but you will see it in 
branches one,two, inxi-perl, inxi-legacy since that is used to confirm remote 
test system patch version updates.

The fourth number, when used, will be alpha-numeric, a common version would be, 
in say, branch one: 2.2.28-b1-02, in other words: branch 1 patch version 2.

In the past, now and then the 4th, or 'patch', number, was used in trunk/master 
branches of inxi, but I've pretty much stopped doing that because it's 
confusing.

inxi does not use the fiction of date based versioning because that imparts no 
useful information to the end user, when you look at say, 2.2.28, and you last 
had 2.2.11, you can know with some certainty that inxi has no major new 
features, just refactors or expansion of existing logic, enhancements, fine 
tunings, and bug fixes. And if you see one with 2.3.2, you will know that there 
is a new feature, almost, but not always, linked to one or more new line output 
items. Sometimes a the changes in the third number can be quite significant, 
sometimes it's a one line code or bug fix. 

A move to a new full version number, like the rewrite of inxi to Perl, would 
reflect in first version say, 2.9.01, then after a period of testing, where most 
little glitches are fixed, a move to 3.0.0. These almost never happen. I do not 
expect for example version 4.0 to ever happen after 3.0 (early 2018), unless so 
many new features are added that it actually hits 3.9, then it would roll over 
to 4.

================================================================================
BSD / UNIX
--------------------------------------------------------------------------------

BSD support is not as complete as GNU/Linux support due to the fact some of the 
data simply is not available, or is structured in a way that makes it unique to 
each BSD, or is difficult to process. This fragmentation makes supporting BSDs 
far more difficult than it should be in the 21st century. 

The BSD support in inxi is a slowly evolving process. Evolving in the strict 
technical sense of evolutionary fitness, following fitness for purpose, that is 
(like OpenBSD's focus on security and high quality code, for instance), not as 
in progressing forwards. Features are being added as new data sources and types 
are discovered, and others are being dropped, as prior data sources degenerate 
or mutate to a point where trying to deal with them stops being interesting. 

Once it starts growing evident that a particular branch has hit a dead end and 
no longer warrants the time required to follow it to its extinction, support 
will be reduced to basically maintenance mode. In other words, inxi follows this 
evolutionary process, and does not try to revive dead or dying branches, since 
that's a waste of time.

Note that due to time/practicality constraints, in general, only the original 
BSD branches will be supported: OpenBSD+derived; FreeBSD+derived; NetBSD+derived 
(in that order of priority, with a steep curve down from first to last). With 
the caveat that since it's my time being volunteered here, if the BSD in 
question has basically no users, or has bad tools, or no usable tools, or 
inconsistent or unreliable tools, or bad / weak data, or, worst, no actual clear 
reason to exist, I'm not willing to spend time on it as a general rule. 

Other UNIX variants will generally only get the work required to make internal 
BSD flags get set and to remove visible output errors. I am not interested in 
them at all, zero. They are at this point basically historical artifacts, of 
interest only to computer museums as far as I'm concerned.

--------------------------------------------------------------------------------
TRUE BSDs 
--------------------------------------------------------------------------------

All BSD issue reports unless trivial and obvious will require 1 of two things:

1. a full --debug 21 data dump so I don't have to spend days trying to get the 
information I need to resolve the issue, file by painful file, from the issue 
poster. This is only the start of the process, and realistically requires 2. to 
complete it.

2. direct SSH access to at least a comparable live BSD version/system, that is, 
if the issue is on a laptop, access has to be granted to the laptop, or a 
similar one. 

Option 2 is far preferred because in terms of my finite time on this planet of 
ours, the fact is, if I don't have direct (or SSH) access, I can't get much 
done, and the little I can get done will take 10 to 1000x longer than it should. 
That's my time spent (and sadly, with BSDs, largely wasted), not yours. 

I decided I have to adopt this much more strict policy with BSDs after wasting 
untold hours on trying to get good BSD support, only to see that support break a 
few years down the road as the data inxi relied on changed structure or syntax, 
or the tools changed, or whatever else makes the BSDs such a challenge to 
support. In the end, I realized, the only BSDs that are well supported are ones 
that I have had direct access to for debugging and testing. 

I will always accept patches that are well done, if they do not break GNU/Linux, 
and extend BSD support, or add new BSD features, and follow the internal inxi 
logic, and aren't too long. inxi sets initial internal flags to identify that it 
is a BSD system vs a GNU/Linux system, and preloads some data structures for BSD 
use, so make sure you understand what inxi is doing before you get into it.

--------------------------------------------------------------------------------
APPLE CORPORATION OSX
--------------------------------------------------------------------------------

Non-free/libre OSX is in my view a BSD in name only. It is the least Unix-like 
operating system I've ever seen that claims to be a Unix, its tools are mutated, 
its data randomly and non-standardly organized, and it totally fails to respect 
the 'spirit' of Unix, even though it might pass some random tests that certify a 
system as a 'Unix'. 

If you want me to use my time on OSX features or issues, you have to pay me, 
because Apple is all about money, not freedom (that's what the 'free' in 'free 
software' is referring to, not cost), and I'm not donating my finite time in 
support of non-free operating systems, particularly not one with a market 
capitalization hovering around 1 trillion dollars, with usually well north of 
100 billion dollars in liquid assetts. 

================================================================================
MICROSOFT CORPORATION WINDOWS
--------------------------------------------------------------------------------

To be quite clear, support for Windows will never happen, I don't care about 
Windows, and don't want to waste a second of my time on it. I also don't care 
about cygwin issues, beyond maybe hyper basic issues that can be handled with a 
line or two of code. inxi isn't going to ruin itself by trying to handle the 
silly Microsoft path separator \, and obviously there's zero chance of my trying 
to support PowerShell or whatever else they come up with. 

While I would consider doing Apple stuff if you paid my hourly full market 
rates, in advance, I would not consider touching Windows for any amount of 
money. My best advice there is, fork inxi, and do it yourself if you want it. 
You'll soon run screaming from the project however, once you realize what a 
nightmare you've stepped into.

If you are interested in something like inxi for Windows, I suggest, rather than 
forking inxi, you just start out from scratch, and build the features up one by 
one, that will lead to much better code.

### EOF ###
