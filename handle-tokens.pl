#!/usr/bin/perl

$|++;

use File::Copy;
use File::Find;

my $path    = shift;
my $search  = shift;
my $replace = shift;
my $version = shift || 1;

my @altered = ();
my @executable = ();

find(
	{
		wanted => sub {
			my $filename = shift;

#			return unless ($File::Find::name =~ m#/(bin|etc)/#);
			return unless ($File::Find::name =~ m#/(bin|etc|[^/]*webapps/opennms/[^/]*INF)/#);
			return unless (-f $File::Find::name);
			# shortcut some known non-translated files
			return if ($File::Find::name =~ /\.(jsp|html)$/);

			if (is_text($File::Find::name)) {
				tokenize_file($File::Find::name);
			}
			if ($File::Find::name =~ m#/bin/#) {
				push(@executable, $File::Find::name);
			}
		},
		follow => 1,
	},
	$path,
);

open (FILEIN, 'install.xml.in') or die "can't read from install.xml.in: $!";
open (FILEOUT, '>install.xml') or die "can't write to install.xml: $!";
while (<FILEIN>) {
	if (/\@parsable_files\@/) {
		for my $file (@altered) {
			$file =~ s/${path}/\$UNIFIED_INSTALL_PATH/;
			print FILEOUT "\t\t\t<parsable targetfile=\"$file\" />\n";
		}
		for my $file (@executable) {
			$file =~ s/${path}/\$UNIFIED_INSTALL_PATH/;
			print FILEOUT "\t\t\t<executable targetfile=\"$file\" stage=\"never\" />\n";
		}
	} elsif (/\@appversion\@/) {
		print FILEOUT "\t\t<appversion>$version</appversion>\n";
	} else {
		print FILEOUT;
	}
}
close (FILEOUT);
close (FILEIN);

sub is_text {
	my $filename = shift;
	
	chomp(my $type = `file "$filename"`);
	return $type =~ /^[^\:]+\:\s*.*?\btext\b/;
}

sub tokenize_file {
	my $filename = shift;

	my $line;
	my $changed = 0;
	
	print "tokenizing $filename... ";
	open (FILEIN, $filename) or die "unable to read from $filename: $!";
	open (FILEOUT, '>' . $filename . '.tmp') or die "unable to write to $filename.tmp: $!";
	while ($line = <FILEIN>) {
		if ($line =~ s/${search}/${replace}/gs) {
			$changed++;
		}
		print FILEOUT $line;
	}
	close (FILEOUT);
	close (FILEIN);

	if ($changed) {
		print "OK\n";
		unlink($filename);
		move($filename . '.tmp', $filename);
		push(@altered, $filename);
	} else {
		print "UNCHANGED\n";
		unlink($filename . '.tmp');
	}
}
