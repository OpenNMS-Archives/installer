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
my @jars = ();

find(
	{
		wanted => sub {
			my $filename = shift;

			return unless ($File::Find::name =~ m#/(bin|etc|jetty-webapps/opennms/[^/]*INF)/#);
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

find (
	{
		wanted => sub {
			my $filename = shift;

			return unless ($File::Find::name =~ m#/lib/#);
			return unless ($File::Find::name =~ m#\.jar$#);
			return if ($File::Find::name =~ m#^.*/contrib/.*$#);
			return if ($File::Find::name =~ m#^.*/[^/]*webapps/opennms[^/]*/.*$#);
			return if ($File::Find::name =~ m#^.*opennms-.*-provisioning-adapter.*$#);
			return if ($File::Find::name =~ m#^.*opennms-rancid.*$#);
			push(@jars, $File::Find::name);
		},
		follow => 1,
	},
	$path,
);

for my $installfile ('install.xml', 'install-1.6.xml') {
	open (FILEIN, "$installfile.in") or die "can't read from $installfile.in: $!";
	open (FILEOUT, ">$installfile") or die "can't write to $installfile: $!";
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
		} elsif (/\@jar_files\@/) {
			for my $file (@jars) {
				$file =~ s#^.*?/lib/##;
				print FILEOUT "\t\t\t<singlefile src=\"lib/$file\" target=\"\$UNIFIED_INSTALL_PATH/lib/$file\" />\n";
			}
		} elsif (/\@appversion\@/) {
			print FILEOUT "\t\t<appversion>$version</appversion>\n";
		} else {
			print FILEOUT;
		}
	}
	close (FILEOUT);
	close (FILEIN);
}

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
