================================================================================
README for inxi-perl development branch: pinxi
================================================================================
FILE:    README.txt
VERSION: 1,2
DATE:    2023-12-25

--------------------------------------------------------------------------------
CODEBERG SOURCE REPO
--------------------------------------------------------------------------------

Notice: as of 2023-12-25 the inxi-perl/pinxi branch will no longer receive 
updates. To get to new pinxi, simply run: pinxi -U then pinxi -U again and you
will be switched to the new branch version. 

Packagers: Make sure to change your package URLs and repos to use codeberg.org.

DO NOT USE THIS BRANCH! It is here only to allow pinxi versions to get updated
one time to get the new codeberg.org/smxi/pinxi download URLs.

This branch will remain static after the end of 2023, again, merely to allow 
pinxi -U to update one time to get the new codeberg updating URLs.

--------------------------------------------------------------------------------

Remember that is is NOT the master branch of inxi, this is the old inxi-perl 
branch of pinxi, the development version of inxi, aka, next inxi, and as such, 
this should only be used by expert users. pinxi how has its own repo at 
codeberg.

Please file issue reports or feature requests at:

https://codeberg.org/smxi/pinxi

or if you prefer the master inxi repo:

https://codeberg.org/smxi/inxi

The github inxi-perl branch will be retained so users can update from it, but
it should not be used for any other purpose, so if you are here, go to codeberg
and start over!

Please take the time to read this helpful article from the Software Freedom
Conservancy:

https://sfconservancy.org/GiveUpGitHub/

Any use of this project's code by GitHub Copilot, past or present, is done 
without my permission. I do not consent to GitHub's use of this project's code 
in Copilot.

================================================================================

Clone pinxi:

git clone https://codeberg.org/smxi/pinxi

Install pinxi for testing. Note that the -U option works the same as the inxi 
main repo master branch, so only the initial install is required:

wget -O pinxi https://codeberg.org/smxi/pinxi/raw/master/pinxi

Shortcut download path for codeberg.org (easier to remember and type):
wget -O pinxi smxi.org/pinxi

pinxi -U --man also installs the man page from pinxi, which is the development 
branch for the master man page.

