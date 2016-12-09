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
use 5.010;
use Getopt::Long;
use Cwd;
####################
# USAGE message:
my $usageMsg = "USAGE: ./getFastaSeq.pl --fasta=\'<FILE>\' --numberSeqsPerFile=<NUM> --ordered=<TRUE|FALSE>\n";

####################
# Get working directory and move to that directory.
my $dir = getcwd;
chdir $dir;

die "Error: all Options must be given.\n" . "$usageMsg" unless (@ARGV == 3);

####################
# Read all parameters from command line options.

my $fasta;
my $numSeqs;
my $order;

GetOptions ("fasta=s" => \$fasta,
		"numberSeqsPerFile=i" => \$numSeqs,
		"ordered=s" => \$order)
or die("Error in command line arguments.\n". "$usageMsg");

####################
# Catch user errors.

die "Error: \"$order\" is neither \"TRUE\" nor \"FALSE\"" 
	unless ( $order eq "TRUE" || $order eq "FALSE");

die "Error: Option not initialized.\n" . "$usageMsg" unless ($fasta && $numSeqs && $order);
####################
# Read fasta file.

my %seq;
my @ordering;

open my $fh, "<", $fasta or die "Error: $fasta $!\n";

{
	my $last;
	while (<$fh>) {
		chomp;
		if (/\A>/) {
			$seq{$_} = "";
			$last = $_;
			push @ordering, $last;
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

my $counter = 1;

# Avoid first if-clause in the first iteration by initialization of $seqCounter.
my $seqCounter = 0;

my $ofh;

if ($order eq "FALSE") {
	foreach my $header (sort keys %seq) {
		if ($seqCounter >= $numSeqs) {
			$counter ++;
			$seqCounter = 0;
			close $ofh;
		} else {
			if ($seqCounter == 0) {
				my $outName = "in_" . "$counter" . "_.fa";
				open $ofh, ">", $outName or die "Error: $outName: $!\n";
			}
			print $ofh "$header\n";
			print $ofh "$seq{$header}\n";
			$seqCounter ++;
		}
	}
} elsif ($order eq "TRUE") {
	foreach my $header (@ordering) {
		if ($seqCounter >= $numSeqs) {
			$counter ++;
			$seqCounter = 0;
			close $ofh;
		} else {
			if ($seqCounter == 0) {
				my $outName = "in_" . "$counter" . "_.fa";
				open $ofh, ">", $outName or die "Error: $outName: $!\n";
			}
			print $ofh "$header\n";
			print $ofh "$seq{$header}\n";
			$seqCounter ++;
		}
	}
}
