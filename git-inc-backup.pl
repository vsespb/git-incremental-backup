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

	if (first { chomp; $_ eq $remote_name } cmd(qq{$git_command remote})) {
		cmd(qq{$git_command fetch $remote_name});
		my @branches = cmd(qq{$git_command branch});
		
		
		my $refs = join(" ",
			map { /^[\s\*]*(.*)$/; $1 } cmd(qq{$git_command branch}),
			map { /^\s*(.*)$/; "^$1" } cmd(qq{$git_command branch -r})
		);
		
		my $new_filename = sprintf("%s%s_%04d.bundle", $backupdir, $name, 2);
		cmd(qq{$git_command bundle create $new_filename $refs});
		#TODO: replace remote
	} else {
		print "FIRST\n";
		my $new_filename = sprintf("%s%s_%04d.bundle", $backupdir, $name, 1);
		cmd(qq{$git_command bundle create $new_filename --all});
		cmd(qq{$git_command remote add $remote_name $new_filename});
	}
	
} elsif ($command eq 'restore') {
	my $i = 0;
	while (1) {
		++$i;
		my $new_filename = sprintf("%s%s_%04d.bundle", $backupdir, $name, $i);
		last unless -f $new_filename;
		if ($i == 1) {
			cmd(qq{git clone $new_filename $gitdir });
		} else {
			cmd(qq{git --git-dir ${gitdir}.git remote add $remote_name $new_filename});
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
		}
	}
}

sub cmd
{
	my ($s) = @_;
	print ":[$s]\n";
	return `$s`;
}

__END__
