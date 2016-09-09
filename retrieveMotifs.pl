#! /usr/bin/perl

################################################################################
# This perl script through sam files and prepares coordinates for motif extraction. 
# Attention: It is a prerequisite that it is a sorted sam file by coordinates of the
# subject/reference (NOT the query) sequence!!!
################################################################################

use utf8;
use 5.010;
use strict;
use warnings;
use Getopt::Long; #command line option module
use Cwd;	#module to provide information about current directory

####################
# Get working directory and move to that directory.
my $dir = getcwd;
chdir $dir;

####################
# USAGE message:
my $usageMsg = "USAGE: ./retrieveMotifs.pl --samFile=<FILE>\n";

# Explain to the user to use a mapped and sorted SAM file!
warn ("\nWARNING:\n");
warn ("\nAttention: Used SAM file must be pre-sorted by coordinates of the subject/reference (NOT the query) sequence!!!\n");
warn ("\nThis warning is always printed for the user. There is currently no routine in this script for check this condition.\n");

####################
# Catch argument errors.
warn ("\nWarning: All Arguments are required.\n\n") unless (@ARGV == 1);

####################
# Read all parameters from command line options.

my $samFile;

GetOptions ("samFile=s" => \$samFile)
or die("Error in command line arguments.\n" . "$usageMsg");

my %parsedArgs = (fastaFile => \$samFile);

####################
# Catch argument errors.
my $missedArg = 0;
foreach my $arg (sort keys %parsedArgs) {
	$missedArg = &argumentError($arg) unless (${$parsedArgs{$arg}} eq "0" || ${$parsedArgs{$arg}});
}

die "Error: Necessary arguments not provided.\n\n$usageMsg\n" if ($missedArg);

####################
# Read from sam file and store motif positions.

open my $fh, "<", $samFile or die "Error: $!\n";

my %motifs;

while (<$fh>) {
	chomp; 
	my @fields = split /\t/;
	my $gene = $fields[2];
	my $motifStart = $fields[3];
	my $motifEnd = $motifStart + length $fields[9];
	if ($motifs{$gene}) {
		$motifs{$gene}->{$motifStart} = $motifEnd;
	} else {
		$motifs{$gene} = { $motifStart => $motifEnd };
	}
}

close $fh;

####################
# Compare motifs and extract consensus regions.

my %finishedMotifs;
my $lastStart = 0;
my $hit = 0;

foreach my $gene (sort keys %motifs) {
	# Sort the motif start positions numerically in ascending fashion.
	foreach my $motifStart (sort {$a <=> $b} keys %{ $motifs{$gene} }) {
		# If the last motif has an overlap with current motif then
		# keep the start position of the last motif and the end position
		# of the current motif. Else create a new motif.
		if ($lastStart
			&& ($motifs{$gene}->{$lastStart} > $motifStart) ) {

			# Hit for same motif recognized.
			$hit = 1;

			if ( $finishedMotifs{$gene} ) {
				$finishedMotifs{$gene}->{$lastStart} = $motifs{$gene}->{$motifStart}; 
			} else {
				$finishedMotifs{$gene} = { $lastStart => $motifs{$gene}->{$motifStart} };
			}
		} 
		
		elsif (!$lastStart
				|| ($motifs{$gene}->{$lastStart} < $motifStart) ) {

			# Hit for same motif NOT recognized.
			$hit = 0;

			if ( $finishedMotifs{$gene} ) {
				$finishedMotifs{$gene}->{$motifStart} = $motifs{$gene}->{$motifStart}; 
			} else {
				$finishedMotifs{$gene} =  { $motifStart => $motifs{$gene}->{$motifStart} };
			}
		}
	
		# Define a new start position only if there weren't any hits for the last one left.	
		unless ($hit) {
			$lastStart = $motifStart;
		}
	}
	# Reset $lastStart to zero.
	$lastStart = 0;
}

####################
# Print results.

print "###gene\tmotifStart\tmotifEnd\n";

foreach my $gene (sort keys %finishedMotifs) {
	foreach my $motifStart (sort {$a <=> $b} keys %{ $finishedMotifs{$gene} }) {
		print "$gene\t$motifStart\t$finishedMotifs{$gene}->{$motifStart}\n";
	}
}

########################################
# Subroutines:

####################
# Print out error message for missing command line argument.
sub argumentError {
	my $missingArg = shift;
    	warn "Error \"--$missingArg\": Argument not initialised.\n";
	return 1;
}


