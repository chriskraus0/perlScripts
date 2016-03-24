#! /usr/bin/perl

################################################################################
# This perl script goes through any fasta file and writes each entry into 
# a separate file.
################################################################################

####################
# Imports:
use warnings;
use strict;
use utf8;
use 5.010A
use Getopt::Long;
use Cwd;
####################
# USAGE message:
my $usageMsg = "USAGE: ./getFastaSeq.pl --fasta=\'<FILE>\'\n";

####################
# Get working directory and move to that directory.
my $dir = getcwd;
chdir $dir;

####################
# Read all parameters from command line options.

my $fasta;

GetOptions ("fasta=s" => \$fasta)
or die("Error in command line arguments.\n". "$usageMsg");

####################
# Read fasta file.

my %seq;

open my $fh, "<", $fasta or die "Error: $fasta $!\n";

{
	my $last;
	while (<$fh>) {
		chomp;
		if (/\A>/) {
			$seq{$_} = "";
			$last = $_;
		} elsif (/\A\S/) {
			if ($seq{$last}) {
				$seq{$last} .= $_;
			} else {
				$seq{$last} = $_;
			}
		}
	}
}

close $fh;

$counter = 1;

foreach my $header (sort keys %seq) {
	my $outName = "in_" . "$counter" . "_.fa";
	open my $ofh, ">", $outName or die "Error: $outName: $!\n";
	print "$header\n";
	print "$seq{$header}\n";
	close $ofh;
}
