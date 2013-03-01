#!/usr/bin/perl

use strict;
use warnings;

use List::Util qw/first/;
use Cwd;

sub in_dir($&)
{
	my $saveddir= getcwd();
	chdir(shift);
	shift->();
	chdir($saveddir);
}


my ($name, $gitdir, $backupdir);
my $command = shift @ARGV;
if ($command eq 'backup') {
	($name, $gitdir, $backupdir) = @ARGV;
} elsif ($command eq 'restore') {
	($name, $backupdir, $gitdir) = @ARGV;
} else {
	die;
}

my $remote_name = 'backup_bundle';

my $git_command = qq{git --git-dir $gitdir};

if ($command eq 'backup') {

	my @existing = get_existing_backups();
	if (@existing) {
		$existing[-1] =~ /\_(\d+).bundle$/;
		my ($old_filename, $new_filename) = map { sprintf("%s%s_%04d.bundle", $backupdir, $name, $_) } ($1, $1 + 1);
		cmd(qq{$git_command remote add $remote_name $old_filename});
		
		cmd(qq{$git_command fetch $remote_name});
		my $refs = join(" ", get_local_branches(), map { "^$_" } get_remote_branches());
		
		cmd(qq{$git_command bundle create $new_filename $refs});
		
		cmd($git_command, qq{bundle}, qq{create},
			sprintf("%s%s_%04d.bundle", $backupdir, $name, map { $1 + 1 } (sort glob($backupdir.$name."_*.bundle"))[-1] =~ /\_(\d+).bundle$/),
			map { /^[\s\*]*(.*)$/; $1 } cmd($git_command, qq{branch}),
			map { "^$_" } map { /^\s*(.*)$/; $1 } cmd($git_command, qq{branch -r}));
		cmd(qq{$git_command remote rm $remote_name});
	} else {
		print "FIRST\n";
		my $new_filename = sprintf("%s%s_%04d.bundle", $backupdir, $name, 1);
		cmd(qq{$git_command bundle create $new_filename --all});
	}
	
} elsif ($command eq 'restore') {
	my $i = 0;
	for (get_existing_backups()) {
		last unless -f;
		if ($i == 0) {
			cmd(qq{git clone $_ $gitdir });
			$i++;
		} else {
			cmd(qq{git --git-dir ${gitdir}.git remote add $remote_name $_});
			cmd(qq{git --git-dir ${gitdir}.git fetch $remote_name});
			print cmd(qq{git --git-dir ${gitdir}.git branch -r});
			
			in_dir $gitdir => sub {
				for (grep { defined } map { m!^\s*\Q$remote_name\E/(.*)$! ? $1 : undef } cmd(qq{git --git-dir ${gitdir}.git branch -r})) {
					# TODO: work-dir simply not work here
					# http://stackoverflow.com/questions/11292057/git-windows-git-pull-cannot-be-used-without-a-working-tree 
					cmd(qq{git --git-dir ${gitdir}.git checkout $_});
					cmd(qq{git --git-dir ${gitdir}.git pull $remote_name $_});
				}
			};
			cmd(qq{git --git-dir ${gitdir}.git remote rm $remote_name});
		}
	}
}

sub get_local_branches
{
	map { /^[\s\*]*(.*)$/; $1 } cmd(qq{$git_command branch})
}

sub get_remote_branches
{
	map { /^\s*(.*)$/; $1 } grep { ! m!\->! } cmd(qq{$git_command branch -r})
}

sub get_existing_backups
{
	sort glob($backupdir.$name."_*.bundle")
}

sub cmd
{
	my ($s) = @_;
	print ":[$s]\n";
	return `$s`;
}

__END__
