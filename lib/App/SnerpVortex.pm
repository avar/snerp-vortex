package App::SnerpVortex;
use strict;
use warnings;

1;

__END__

=head1 NAME

App::SnerpVortex - Replay a Subversion dump into Git/Filesystem/etc.

=head1 About

Snerp Vortex is an anagram of SVN Exporter.  It aims to be a faster,
more reliable way to create new repositories from Subversion dumps
than using git-svn and various abandonment techniques.

Faster?  On my canonical example repository (POE), Snerp Vortex
converts 2824 Subversion commits to Git in about 250 seconds.

Not fast enough?  I'm looking for someone with git-fast-import clue to
help make it faster.  For comparison, the same repository can be
converted into a flat filesystem in about 70 seconds.

More satisfying?  Snerp Vortex uses path analysis to detect hints
about tags and branches.  It then adjusts its assumptions according to
actual repository use.  Tags that are modified later become branches.
Branches that are never touched are demoted to tags.

There is rudimentary support for multiple projects per repository, but
it needs love.

=head2 Toolset

Snerp Vortex is a chain of three tools.

=over

=item snanalyze

snanalyze examines a Subversion dump and produces an XML file
describing its structure.  Sample usage:

	./snanalyze --dump poe.svndump > poe.xml

=item snassign-gui

snassign-gui is a Gtk2 utility to browse an XML repository analysis.
With it, one can page back and forth through significant revisions to
see how snanalyze interpreted structural changes.  It's intended to be
an analysis editor with which a human may assign roles to different
directories at particular revisions.  Some repositories are just
hopeless without a human's touch.  Sample usage:

	./snassign-gui --analysis poe.xml

=item snerp

Finally there's snerp itself.  Given a Subversion dump and an XML
analysis, it will attempt to replay the repository into a new format.
Sample usage:

	./snerp \
		--replayer git \
		--authors $HOME/projects/.authors \
		--dump $HOME/projects/poe.dump \
		--analysis $HOME/projects/poe.xml \
		--tmp $HOME/projects/snerp-tmp \
		--into $HOME/projects/new-git-repot

All three tools respond to --help.

=back

Snerp Vortex requires a Subversion dump file, which is generally
created by running svnadmin dump on the machine that hosts the
repository.  I've just come across a remote svn dump utility that may
help when you don't have direct access to the svn host:

http://rsvndump.sourceforge.net/

Snerp Vortex comes with some utilities and scripts that will
eventually be cleaned up and organized.  Until then:

	mkramdisk_osx - Create a 1 GB RAM disk with a case-sensitive
	filesystem.

	snub - Snub the file contents of a dump.  Retains the file and
	directory structure, but the resulting dump and replays are much
	smaller.  Written for Ævar Arnfjörð Bjarmason's six-gigabyte dump,
	which triggers a hard to reproduce bug.

	diff-test - Diffs a svn and git checkout of the same repository at
	the same revision.

	dev-* and test-* - One-off test scripts.

Snerp Vortex is late alpha quality.  It seems to work in limited
tests, but there's no guarantee it will work for you.  Fixes are
greatly appreciated.

=head1 OSX Users

Get yourselves a case-sensitive filesystem.  This is easier done than
said.  Disk Utility can create empty random-access disk images with
the filesystems of your choice.  They mount in /Volumes and are
accessible like any other filesystem.

Even better, build a RAM disk if you have the memory to spare.  See
the mkramdisk_osx utility in this project.

=head1 Improvements?

I've heard that git-fast-import can potentially make Snerp Vortex a
lot faster.  The program should be flexible enough to support it
without much fuss.

I may not get around to it, as I'm rapidly running out of Subversion
repositories to convert.  If you want or need this, please consider
contributing.

=head1 Testing

Until there's a proper test framework, here's the plan from a recent
test I ran.

Create a dummy repository, check it out and establish a test case
within it.

	svnadmin create binary-svn
	svn co file:///home/troc/projects/git/binary-svn binary-co          
	cd binary-co
	cp ~/Downloads/wtf.gif .
	svn add wtf.gif
	svn commit -m 'Commit a binary file.' 

Dump the repository.

	cd ..
	svnadmin dump binary-svn > binary-svn.dump

If it's a really huge repository, then early debugging might go better
if the contents of all the files is omitted.

	cat huge.dump | ./snub --file - > smaller.dump

Replay the repository into git.

	cd snerp-vortex

	time ./snerp \
		--replayer=git \
		--authors=/home/troc/projects/authors.txt \
		--into=/Volumes/snerp-vortex-workspace/binary-git \
		--dump=../binary-files.dump \
		--copies=/Volumes/snerp-vortex-workspace/binary-snerp-copies \
		--verbose

Verify that the replayed binary file works.

	open /Volumes/snerp-vortex-workspace/binary-git/wtf.gif

The distribution's t/dumps directory is the repository for test dumps.

=head1 Design Notes

There are multiple kinds of branch, some of which don't map to Git's
idea of branches.  For example, there's the branch that is someone's
personal scratch workspace.  Then there's the branch intended to be
merged back later.

Tags and branches are defined by usage patterns, not by the
directories in which they live.  Proper branches and tags are created
by copying, not by creating directories.  The difference is that
branches are modified after copying while tags are not.  Subversion
"tags" are frequently modified, and "branches" are sometimes never
touched.  Snerp Vortex tries to be smart about this.

Subprojects are not attempted to be spun off into separate
repositories.  In personal experience, spin-off projects are moved
from /trunk into some new directory, possibly also in trunk.  The
files are then modified there.  To preserve full history, I plan to
fork the full Git repository and follow Michaelangelo's advice: carve
away everything that isn't the project.  Better plans are welcome.

Subversion can tag subdirectories within trunk.  After all, tags are
just directory copies.  Git cannot.  Subversion tags are translated to
Git by tagging HEAD at the relative moment when the Subversion tree
has been tagged.  Is there a better way to do this?

=cut
