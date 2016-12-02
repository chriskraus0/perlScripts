#! /usr/bin/perl

################################################################################
# ./getFastqFromFile.pl
# This script goes through a fastq file and extracts all reads with a specific header.
################################################################################

use strict;
use utf8;
use 5.010;
use warnings;

use Getopt::Long; #command line option module
use Cwd;	#module to provide information about current directory

####################
# Get working directory and move to that directory.
my $dir = getcwd;
chdir $dir;

####################
#USAGE message:
my $usageMsg = "USAGE: ./getFastqFromFile.pl --fastq=<FILE> --batchHeader=<FILE>\n\n";
####################

#Catch argument errors.
die ("\nError: All Arguments are required.\n\n" . "$usageMsg") unless (@ARGV == 2);

####################
#Read all parameters from command line options.

my $fastqFile;
my $headerFile;

GetOptions ("fastq=s" => \$fastqFile,
	"batchHeader=s" => \$headerFile)
or die("Error in command line arguments.\n" . "$usageMsg");

####################
# Read batchHeader file.

my %targets;

open my $fh, "<", $headerFile or die "Error: \"$headerFile\": $!\n";

while (<$fh>) {
	chomp; 
	$targets{$_}=1;
}

close $fh;

####################
# Read fastq file.
open $fh, "<", $fastqFile or die "Error: \"$fastqFile\": $!\n";

my $header = "";
my $hit = 0;
my $qualHit = 0;
my $qualString = "";
my $seqID = "";
my $seq = "";

while (<$fh>) {
	chomp;
	if (/\A@/ && !$qualHit) {
		$hit = 0;
		$header = $_;
		($seqID, my $dummy) = split / /, $header;
		$seqID =~ s/\A@//;
		if ($targets{$seqID}) {
			$hit = 1;
		}
		$qualHit = 0;
		$qualString = "";
	} elsif (/\A[ACGNT]/ && $hit && !$qualHit) {
		$seq = $_;
		$hit = 1;
	} elsif (/\A\+/ && $hit) {
		$qualHit = 1;
	} elsif ($hit && $qualHit) {
		$qualString = $_;
		$qualHit = 0;
	}
	if ($hit && $qualString) {
		$hit = 0;
		$qualHit = 0;
		$targets{$seqID} = [ ($header, $seq, $qualString) ];
		print "$targets{$seqID}->[0]\n";
		print "$targets{$seqID}->[1]\n";
		print "+\n";
		print "$targets{$seqID}->[2]\n";
		$targets{$seqID} = "";
		$qualString = "";
		$seq = "";
	}
}

close $fh;

####################
# Print results.

#foreach my $id (keys %targets) {
#	print "$targets{$id}->[0]\n";
#	print "$targets{$id}->[1]\n";
#	print "+\n";
#	print "$targets{$id}->[2]\n";
#}
