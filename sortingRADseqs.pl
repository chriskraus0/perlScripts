#! /usr/bin/perl

################################################################################
# ./sortingRADseqs.pl
# This script goes through a forward RAD tag fastq read file and extracts fastq
# entries and their position in the file.
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
my $usageMsg = "USAGE: ./sortingRADseqs.pl --midResPattern=<PATTERN> --fwdFastq=<FILE> --revFastq=<FILE> --outputFWD=<FILE> --outputREV=<FILE> --outputFWD=<FILE> --outputREV=<FILE>\n\n";
####################
#Catch argument errors.
die ("\nError: All Arguments are required.\n\n" . "$usageMsg") unless (@ARGV == 5);

####################
#Read all parameters from command line options.

my $midResPattern;
my $fwdFastq;
my $revFastq;
my $outputFWD;
my $outputREV;

GetOptions ("midResPattern=s" => \$midResPattern,
	"fwdFastq=s" => \$fwdFastq,
	"revFastq=s" => \$revFastq,
	"outputFWD=s" => \$outputFWD,
	"outputREV=s" => \$outputREV)
or die("Error in command line arguments.\n" . "$usageMsg");

# Catch user errors.
die "Error: --midResPattern: \"$midResPattern\" must contain only N|A|T|G|C" unless ($midResPattern =~ /[AGCNT]/);

####################
# Read forward fastq file.

open my $fh, "<", $fwdFastq or die "Error: \"$fwdFastq\": $!\n";

my %targets;
my $header = "";
my $hit = 0;
my $qualHit = 0;
my $qualString = "";
my $seqID = "";
my $seq = "";
my $mid = "";

while (<$fh>) {
	chomp;
	if (/\A@/) {
		$header = $_;
		($seqID, my $dummy) = split / /, $header;
		$hit = 0;
		$qualHit = 0;
		$qualString = "";
	} elsif (/\A$midResPattern/) {
		my $rawSeq = $_;
		my $len = length $midResPattern;
		$mid = substr $rawSeq, 0, $len;
		$seq = substr $rawSeq, $len;
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
		$header = "$header" . " " . "$mid";
		$targets{$seqID} = [ ($header, $seq, $qualString) ];
		$qualString = "";
	}
}

close $fh;

####################
# Read reverse fastq file.

open $fh, "<", $revFastq or die "Error: \"$revFastq\": $!\n";

$hit = 0;
$qualHit = 0;
my $revID = "";

while (<$fh>) {
	chomp;
	if (/\A@/) {
		$hit = 0;
		$qualHit  = 0;
		$header = $_;
		($revID, my $dummy) = split / /, $header;
		if ($targets{$revID}) {
			$hit = 1;
			push @{ $targets{$revID} }, $header;
		}
	} elsif ($hit && !$qualHit && !(/\A\+/)) {
		push @{ $targets{$revID} }, $_;
	} elsif ($hit && /\A\+/) {
		$qualHit = 1;
	} elsif ($hit && $qualHit) {
		push @{ $targets{$revID} }, $_;
	}

}

close $fh;

####################
# Print results.

open my $fhFWD, ">", $outputFWD or die "Error: \"$outputFWD\": $!\n";
open my $fhREV, ">", $outputREV or die "Error: \"$outputREV\": $!\n";

foreach my $id (keys %targets) {
	print $fhFWD "$targets{$id}->[0]\n";
	print $fhFWD "$targets{$id}->[1]\n";
	print $fhFWD "+\n";
	print $fhFWD "$targets{$id}->[2]\n";
	print $fhREV "$targets{$id}->[3]\n";
	print $fhREV "$targets{$id}->[4]\n";
	print $fhREV "+\n";
	print $fhREV "$targets{$id}->[5]\n";
}

close $fhFWD;
close $fhREV;
