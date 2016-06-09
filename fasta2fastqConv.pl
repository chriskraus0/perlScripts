#! /usr/bin/perl

################################################################################
# This perl scripts walks through a fasta file and converts its input into fastq
# format.
################################################################################

####################
# Imports.
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
#USAGE message:
my $usageMsg = "USAGE: ./fasta2fastqConv.pl --fasta=<FILE>\n\n"
		. "For help type $0 --help\n\n";


####################
#HELP message:
my $helpMsg = "\nNAME\n\n" 
		. "\t $0 - The aim of this script is to walk through a fasta file\n"
		. "\t and convert fasta input into fastq output.\n\n"
		. "$usageMsg"

		. "ATTENTION\n"
		. "\tThe command line option is required.\n\n"

		. "OPTIONS\n"

		. "\t--help\tprints this help message\n\n"

		. "\t--fasta=<FILE>\tProvide the fasta file for the conversion tool.\n"
		. "\n";

####################
# Catch argument errors.
if (@ARGV == 1 && $ARGV[0] eq "--help") {
	print "$helpMsg";
	exit 0;
}

warn ("\nWarning: All Arguments are required.\n\n") unless (@ARGV == 1);

####################
# Read all parameters from command line options.

my $fasta;
 
GetOptions ("fasta=s" => \$fasta)
or die("Error in command line arguments.\n" . "$usageMsg");

my %parsedArgs = (fasta => \$fasta);

####################
# Catch argument errors.
my $missedArg = 0;
foreach my $arg (sort keys %parsedArgs) {
	$missedArg = &argumentError($arg) unless (${$parsedArgs{$arg}} eq "0" || ${$parsedArgs{$arg}});
}

die "Error: Necessary arguments not provided.\n\n$usageMsg\n" if ($missedArg);

####################
# Read the fasta input form file.

# Save fasta header and sequences in a tree like structure within a hash.
my %seq;

#Keep most of the variables in a local scope.
{
# Save the last encountered fasta header.
	my $header = "";

	open my $fh, "<", $fasta or die "Error: $fasta: $!\n";

	while (<$fh>) {
		chomp;
		if ( /\A>/) {
			# Save the fasta header.
			$header = $_;
			# Remove the ">" sign from the fasta header.
			$header =~ s/\A>//g;
			# Prepare the entries for the hash %seq.
			$seq{$header} = "";
		} elsif (/\A[ACTGactg]/ && $header) {

			# If an sequence entry exists for this fasta header concatenate the current sequence 
			# to the previous, otherwise create a new sequence entry.
			if ($seq{$header}) {
				$seq{$header}= $seq{$header} . $_;
			} else {
				$seq{$header} = $_;
			}
		}
	}
}

####################
# Convert read fasta input into fastq and print it to standard out.

foreach my $header (sort keys %seq) {
	print "\@$header\n";
	print "$seq{$header}\n";
	# Print the quality header.
	print "+$header\n";
	# Add dummy quality sequence.
	for (my $i = 0; $i < length($seq{$header}); $i ++) {
		print "I";
	}
	print "\n";
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


