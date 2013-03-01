#!/usr/bin/perl

use strict;
use warnings;
use lib 'lib';
use File::Path;
use Utils;


rmtree($tempdir);
mkpath($tempdir);
mkdir $source;
mkdir $backup;
mkdir $restore;

cmd qq{git init $source};
die unless -d $sourcegit;
add_file(q{file1});
cmd qq{$command backup myname $sourcegit $backup/};
add_file(q{file2});
cmd qq{git --git-dir $sourcegit --work-tree $source checkout -b development};
add_file(q{file3});
cmd qq{$command backup myname $sourcegit $backup/};


cmd qq{$command restore myname $backup/ $restore/};
compare_repos($source, $restore);

print "OK DONE\n";

