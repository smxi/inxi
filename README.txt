README for inxi - a command line system information tool

NOTE: there is a feature freeze on inxi 2.3.xx development, except 
for bug fixes. All current development is on the 2.9.00-xxx-p branch
which is in alpha or beta states depending on the module being
worked on. Once I view 2.9.00-xxx-p as feature complete or better 
vs inxi 2.3.xx, it will become the current master branch of inxi.

=====================================================================
If you do not want to get the full master with gz history data, which
gets bigger every year, you can clone inxi current using the: 
master-plain branch. 

git clone https://github.com/smxi/inxi --branch master-plain --single-branch

The master-plain branch does not have inxi.1.gz or inxi.tar.gz, and 
so does not suffer from the size inflation that master has. 
=====================================================================
SUPPORT INFO:

Do not ask for basic help that reading the inxi -h / --help menus, or 
man page would show you, and do not ask for features to be added that
inxi already has. Also do not ask for support if your distro refuses to
update its inxi version, some are terrible about that.

DOCUMENTATION: http://smxi.org/docs/inxi.htm 
(smxi.org/docs/ is easier to remember, and is one click away from inxi.htm)
The one page wiki on github is only a pointer to the real resources.

HTML MAN PAGE: http://smxi.org/docs/inxi-man.htm 
INXI OPTIONS: http://smxi.org/docs/inxi-options.htm 
NOTE: both options and man html versions may and probably will lag behind
current inxi because doing documentation is boring, and the man to html
converter I tried is really bad, so it's hard to update the man page html.

ISSUES: https://github.com/smxi/inxi/issues
No issues accepted for non current inxi releases. See below for more on that.

SUPPORT FORUMS: http://techpatterns.com/forums/forum-33.html
This is the best place to place support issues that may be complicated.

If you are developer, use:
DEVELOPER FORUMS: http://techpatterns.com/forums/forum-32.html

SOURCE VERSION CONTROL: https://github.com/smxi/inxi
MAIN BRANCH: master
DEVELOPMENT BRANCHES: inxi-perl, one, two, three, android, bsd
Dev branches are rarely used, but that's where the really hard new features etc
are debugged and worked out. inxi itself has the built in feature to be able
to update itself from anywhere, including these branches, which is very useful
for development and debugging on many user systems.

PULL REQUESTS: inxi is VERY complicated and VERY hard to work on, so unless
you have already talked to me about contributing, and, more important, shown 
that you can actually work with this type of logic, please do not spend time 
trying to work on inxi, unless it's a trivial patch, to the current branch, 
current version. Please: NEVER even think about looking at or using previous 
inxi commits, previous to the current one, as a base for a patch. If you do, 
your patch / pull request will be rejected immediately, without any discussion.

Note further: no core changes will be accepted until inxi 3.0.0 goes live, 
since that's just more stuff I have to port over.

inxi has one and only one release, and that is the current one (plus dev releases,
of course, but those should never be packaged). All previous releases are 
immediately obsolete on the commit of every new release. There is no exception to 
this, and never will be.

Man page updates, doc page updates, etc, of course, are easy and will probably
be accepted, as long as they are done according to the requirements. 

Read below re asking about tagging this rolling software release, short version:
don't ask.

inxi releases early, and releases often, when under development. 

=====================================================================
ABOUT INXI - CORE COMMITMENT TO LONG TERM STABILITY

inxi is a command line system information tool. It was forked from the ancient
and mindbendingly perverse yet ingenius infobash, by locsmif. 

That was a buggy, impossible to update or maintain piece of software, so the
fork fixed those core issues, and made it flexible enough to expand the 
utility of the original ideas. Locmsif has given his thumbs up to inxi, so 
don't be fooled by legacy infobash stuff you may see out there.

inxi is lower case, except when I create a text header here in a file like 
this, but it's always lower case. Sometimes to follow convention I will use
upper case inxi to start a sentence, but i find it a bad idea since 
invariably, someone will repeat that and type it in as the command name, then
someone will copy that, and complain that the command: Inxi doesn't exist...

The primary purpose of inxi is for support, and sys admin use. inxi is used
widely for forum and IRC support, which is I believe it's most common function.

If you are piping output to paste or post, then make sure to turn off the
script colors with the -c 0 flag. Script colors in shell are characters.

With some pain, inxi has gotten to the point where some of its hardware
tools are actually better, more accurate, and astoundingly, faster, than their 
C version equivalents, but that's not because inxi is great, it's because 
those other tools just aren't well done in my opinion. inxi should ALWAYS
show you your current system state, as far as possible, and should be more
reliable than your own beliefs about what is in your system, ideally. In 
other words, the goal in inxi is to have it be right more than it is wrong
about any system that it runs on. And NEVER to rely on non current system
state data if at all possible. Some things, like memory/ram data, rely on
radically unreliable system self reporting based on OEM filling out data
correctly, which doesn't often happen, so in those cases, you want to 
confirm things like ram capacity with a reputable hardware source, like
crucial.com, which has the best ram hardware tool I know of.

Tthe absolute core mission of inxi is to always work on all systems all the 
time. Well, all linux systems with the core tools inxi requires to operate
installed. Ie, not android, yet. What this means is this: you can have a 10 
year old box, or probably 15, not sure, and you can install today's inxi on 
it, and it will run. It won't run fast, but it will run. I test inxi on a 
200 MHz  laptop from about 1998 to keep it honest. That's also what was 
used to optimize the code at some points, since differences appear as seconds,
not 10ths of seconds.

Once inxi has moved to Perl 5.x, from Bash / Gawk, the commitment to always
work on all hardware no matter how old the OS, with reason, is not changed.
inxi is being written, and tested, on Perl as old as 5.08, and will work on
any system that runs Perl 5.08 or later. Pre 3.0.0 inxi will also run on 
any system no matter how old, within reason, so there should be no difference.

=====================================================================
BSD SUPPORT

BSD support was, with great pain, added, though it's partial and incomplete.
BSDs are simply too hard to work with because of their extreme fragmentation, 
ie, they don't even share one tool you take for granted on GNU/Linux, like
lspci. Nor do they share common methods of reporting system hardware data.
Nor does a single BSD, even within itself, like FreeBSD, even maintain standard
methods across releases. So the BSD support in inxi is basically what it is, 
if more is wanted, then BSD people have to step up and do the work, always'
keeping in mind that all patches to inxi must not break existing functionality
for existing supported platforms, be they BSD or GNU/Linux.

I like real BSDs, like OpenBSD, NetBSD, FreeBSD, etc, and prefer that the tools
in inxi that can be made to work on BSDs, do work, but their refusal to even 
use the same tools or locations or syntaxes for system info simply makes it 
too hard for me to do that work. I will always accept patches that are well 
done however from competent people, if they do not break GNU/Linux, and extend
BSD support. Keep in mind, all patches must be based on tool/file tests, not 
BSD version tests. inxi sets initial internal flags to identify that it is a 
BSD system vs a GNU/Linux system, after that it tests for specific 
applications and resources.

inxi will also start on Darwin, OSX's mutated version of a BSD, but my 
conclusion about darwin is that it is Unix in name only, and I will not spend 
a second of my time adding any further support for that crippled broken 
corporate pseudo-unix system. Don't ask.

If you want to run unix, then OSX is not unix, in my opinion.

=====================================================================
INXI FEATURES AND FUNCTIONALITY

inxi's functionality continues to grow over time, but it's also important
to understand that each core new feature usually requires about 30 days work
to get it stable. So new features are not trivial things, nor is it acceptable
to submit a patch that works only on your personal system. One inxi feature
(-s, sensors data), took about 2 hours to get working in the alpha test on the
local dev system, but then to handle the massive chaos that is actual user
sensors output and system variations, it took several rewrites and about 30
days to get somewhat reliable for about 98% or so of inxi users. So if your
patch is rejected, it's likely because you have not thought it through 
adequately, have not done adequate testing cross system and platform, etc.

=====================================================================
INXI RELEASE/SUPPORT/ISSUES/BUGS INFORMATION:

Important: the only version of inxi that is supported is the latest current 
master branch release. No issue reports or bug reports will be accepted for 
anything other than current master branch. No merges, attempts to patch old code
from old releases, will be considered or accepted. If you are not updated to
the latest inxi, do not file a bug report since it's probably been fixed ages
ago. If your distro isn't packaging a current inxi, then file a bug report 
with them, not here. The only valid working code base for inxi is the current 
release of inxi. Distributions should never feel any advantage comes from using
old inxi releases because inxi has as a core promise to you, the end user, that
it will NEVER require new tools to operate. New tools may be required for a new
feature, but that will always be handled internally by inxi, and will not cause
any operational failures. This is a promise, and I will never as long as I run
this project violate that core inxi requirement. Old inxi is NOT more stable 
than current inxi, it's just old, and lacking in bug fixes and features.

inxi is a rolling release codebase, just like Debian Sid, Gentoo, or Arch 
Linux are rolling release GNU/Linux distributions, with no 'release points'.

Why this is apparently so difficult for some people to grasp is beyond me,
particularly with Debian, that has Sid, a rolling release, un-versioned, no
fixed release point, package pool. All my code is rolling release, some of
it just happens to roll more slowly than others. inxi moves slowly some months,
very rapidly others. When it's moving rapidly, it's often wise to wait for it
to slow down, but you don't have to.

Your distro not updating inxi ever, then failing to show something that is
fixed in current inxi is not a bug, and please do not post it here. File 
the issue with your distro, not here. Updating inxi in a package pool will 
NEVER make anything break or fail, period. It has no version based 
dependencies, just software, like gawk, sed, etc. There is never a valid 
reason to not update inxi in a package pool of any distro in the world.

Sys Admin type inxi users always get the first level of support. ie, convince 
us you run real systems and networks, and your issue shoots to the top of 
the line. As do any real bugs. Failure to supply requested debugger data 
will lead to a distinct lack of interest on our part to help you with a 
bug. ie, saying, oh, x doesn't work, doesn't cut it, unless it's obvious why. 

=====================================================================
TAGS - DO NOT ASK FOR INXI TO BE TAGGED!!

In particular, no issue reports will be accepted relating to tagging inxi 
releases. Why? Because tagging is a bad idea, that leads to insecure code 
and packaging practices, and should not be recommended or used by package 
maintainers. A packager should ALWAYS point to the actual commit they got 
their code from, not a tag attached to that commit. For what should be 
obvious reason, you can move tags, delete them, and point to bad code, 
then good code, all without giving any indication at all that the tag or 
its destination have been changed. In other words, relying on tagging to 
identify code releases is identical to relying on fairy tales for security. 
Point to the release commit ID, if you do, you will be pointing to the 
code you downloaded for your package, if you do not, you won't be.

Github makes that very easy: 
https://github.com/smxi/inxi/tarball/[first 7 characters of commit id]
EXAMPLE: https://github.com/smxi/inxi/tarball/1d37e0d
(click it, you'll see the tarball download)

This is a real link, to a real tarball, of a real commit. It's not a fiction,
a fantasy, a misleading and potentially serious security hole, like a tag.

It's also easier to grab that than the somewhat cludgy git method to grab
a specific git commit id. Apparently with git 2.5, that cludgy method will
be replaced by a more basic thing, that corresponds to the svn way to grab
a commit, by commit number, cleanly.

Further, tagging a rolling release code base is absurd, since every packager
is going to grab the current release of the codebase, unless they are very
confused or misguided (and the best way for me to encourage this type of
confusion and misguided action is by tagging any one release, thus suggesting
it is a static release). Thus I would have to tag every single commit since 
I could never know when say, the Arch Linux maintainer is going to grab his
code, or any other distribution maintainer. Further, I would have to go back
and tag every past commit as well, since each and every one was at the time, 
the current release of inxi. That's without exception, no commit ever done 
in the trunk/master branch of inxi has ever not been the current release, by 
definition.

I shouldn't need to waste time noting something that should be obvious to 
anyone with even a faint clue about code, or secure practices in terms of 
having a real pointer to the code you grabbed, in other words not a tag! 
But I will note it here to avoid being asked again about tagging. A tag 
is a post-it sticky note, and should never be considered as a valid pointer, 
just a convenience in some projects that works for some types of programming 
practices, certainly not mine.

All issue reports opened about tagging will be closed immediately (see issues
70/74 if you must, you won't get any different answer by repeating the same bad 
logic again) without comment. File a distro bug report in your distro of choice
if they insist on asking for this bad idea, that's the right place to handle
the problem.

=====================================================================

INXI VERSION NUMBERING:

inxi uses fairly classic version numbering, where the version numbers actually
mean something.

The version number follows these guidelines:
Using example 2.2.28-6

The first digit(s), "2", is a major version, and almost never changes. Only 
a huge milestone, or if inxi reaches 2.9.xx, when it will simply move up to 
3.0.0 just to keep it clean, would cause a change. 

The second digit(s), "2", means a new real feature has been added. Not a 
tweaked existing feature, an actual new feature, which usually also has a new 
argument option letter attached. The second number goes from 0 to 9, and then
rolls over the first after 9. It could also be adding a very complicated 
expansion of existing features, like Wayland. It depends.

The third, "28", is for everything small, can cover bug fixes, tweaks to 
existing features to add support for something, pretty much anything where you
want the end user to know that they are not up to date. The third goes from 0 
to 99, then rolls over the second.

The fourth, "6", is extra information about certain types of inxi updates. 
I don't usually use this last one in master branch, but you will see it 
frequently in branch one,two, etc development since that is used to confirm 
remote test system updates.

The fourth number, when used, will be alpha-numeric, a common version would be,
in say, branch one: 2.2.28-b1-02, in other words, a branch 1 release, version 2.

In the past, now and then the 4th, or 'patch', number, was used in trunk/master
branches of inxi, but I've pretty much stopped doing that because it's confusing.

inxi does not use the fiction of date based versioning because that imparts no
useful information to the end user, when you look at say, 2.2.28, and you last
had 2.2.11, you can know with some certainty that inxi has no major new 
features, just fine tunings and bug fixes. And if you see one with 2.3.2, you 
will know that there is a new feature, almost, but not always, linked to one 
or more new line output items. Sometimes a fine tuning can be quite 
significant, sometimes it's a one line code fix.

### EOF ###
