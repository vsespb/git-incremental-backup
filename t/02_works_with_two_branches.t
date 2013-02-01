#!/usr/bin/perl

use File::Path;

my $tempdir = q{/tmp/git-backup-tests};
my $command = q{../git-inc-backup.pl};

sub cmd($)
{
	my ($s) = @_;
	print "[$s]\n";
	if (wantarray) {
		my @r = `$s`;
		print @r;
		return @r;
	} else {
		my $r = `$s`;
		print $r;
		return $r;
	}
}


rmtree($tempdir);
mkpath($tempdir);
mkdir my $source = qq{$tempdir/source};
mkdir my $backup = qq{$tempdir/backup};
mkdir my $restore = qq{$tempdir/restore};

#die unless my $restoregit = qq{${restore}/.git};

cmd qq{git init $source};
die unless -d (my $sourcegit = qq{${source}/.git});
add_file(q{file1});
cmd qq{$command backup myname $sourcegit $backup/};
add_file(q{file2});
cmd qq{git --git-dir $sourcegit --work-tree $source checkout -b development};
add_file(q{file3});
cmd qq{$command backup myname $sourcegit $backup/};


cmd qq{$command restore myname $backup/ $restore/};
compare_repos($source, $restore);

sub add_file
{
	my ($file) = @_;
	cmd qq{echo 1 > $source/$file};
	cmd qq{git --git-dir $sourcegit --work-tree $source add $file};
	cmd qq{git --git-dir $sourcegit commit -m "$file"};
}


sub compare_repos
{
	my ($a, $b) = @_;
	my @branch_a = get_branches($a);
	my @branch_b = get_branches($b);
	
	die unless scalar @branch_a == scalar @branch_b;  
	#use Data::Dumper;
	#die Dumper(\@branch_a);
	for (1..scalar @branch_a) {
		my $a_branch = shift @branch_a; 
		my $b_branch = shift @branch_b;
		die "$a_branch eq $b_branch" unless $a_branch eq $b_branch;
		my @a_log = get_log($a, $a_branch);
		my @b_log = get_log($a, $a_branch);
		
		die unless scalar @a_log == scalar @b_log;
		for (1..scalar @a_log) {
			my $a_l = shift @a_log;
			my $b_l = shift @b_log;
			die unless $a_l eq $b_l;
		}
	}
}

print "OK DONE\n";

sub get_branches
{
	my ($a) = @_;
	sort map { /^[\s\*]*(.*)$/; $1 } cmd qq{git --git-dir $a/.git --work-tree $a/.git branch};
}

sub get_log
{
	my ($a, $branch) = @_;
	cmd qq{git --git-dir $a/.git --work-tree $a/.git checkout $branch};
	cmd qq{git --git-dir $a/.git --work-tree $a/.git log --no-color --format=oneline};
}
