package Utils;

require Exporter;
use base qw/Exporter/;

use strict;
use warnings;
             
our $tempdir = q{/tmp/git-backup-tests};
our $command = q{../git-inc-backup.pl};
our $source = qq{$tempdir/source};
our $backup = qq{$tempdir/backup};
our $restore = qq{$tempdir/restore};
our $sourcegit = qq{${source}/.git};

our @EXPORT = qw/cmd add_file compare_repos get_branches get_log $tempdir $command $source $backup $restore $sourcegit/;


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
	die unless @branch_a;
	die unless scalar @branch_a == scalar @branch_b;  
	#use Data::Dumper;
	#die Dumper(\@branch_a);
	for (1..scalar @branch_a) {
		my $a_branch = shift @branch_a; 
		my $b_branch = shift @branch_b;
		die "$a_branch eq $b_branch" unless $a_branch eq $b_branch;
		my @a_log = get_log($a, $a_branch);
		my @b_log = get_log($b, $a_branch);
		
		die unless scalar @a_log == scalar @b_log;
		for (1..scalar @a_log) {
			my $a_l = shift @a_log;
			my $b_l = shift @b_log;
			die unless $a_l eq $b_l;
		}
	}
}



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


1;


