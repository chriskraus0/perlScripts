#! /usr/bin/perl 

################################################################################
# This goes through a csv file extracted from cytoscape and create a adjacent 
# matrix listing all existing interactions between all entries.
################################################################################

# Enable UTF-8 encoding for all file reads.
use open qw( :std :encoding(UTF-8) );

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
my $usageMsg = "USAGE: ./interactomeEdges.pl --inputCsv=<FILE> --output=<FILE>\n"
		. "For help type $0 --help\n";


####################
# HELP message:
my $helpMsg = "NAME\n\n" 
		. "\t $0 - The aim of this script is to walk through a edge csv\n"
		. "\t file exported from cytoscype and export a matrix indicating\n"
		. "\t all interactions by a \"1\" (present) or \"0\" (absent).\n\n"
		
		. "$usageMsg"

		. "ATTENTION\n"
		. "\tAll 2 command line options are required.\n\n"

		. "OPTIONS\n"

		. "\t--help\tprints this help message\n\n"

		. "\t --inputCsv=<FILE>\tInput of the provided csv table\n\n"

		. "\t --output=<FILE>\tFile in which the matrix will be written.\n"
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

my $inputCsv;
my $outputFile;

GetOptions ("inputCsv=s" => \$inputCsv, "output=s" => \$outputFile)
or die("Error in command line arguments.\n" . "$usageMsg");

my %parsedArgs = (inputCsv => \$inputCsv, output => \$outputFile);

####################
# Catch argument errors.
my $missedArg = 0;
foreach my $arg (sort keys %parsedArgs) {
	$missedArg = &argumentError($arg) unless (${$parsedArgs{$arg}} eq "0" || ${$parsedArgs{$arg}});
}

die "Error: Necessary arguments not provided.\n\n$usageMsg\n" if ($missedArg);

####################
# Read the csv file.

# Keep track of all entries and respective interaction in form of a hash.
my %results;

open my $fh, "<", $inputCsv or die "Error: $!\n";

while (<$fh>) {
	chomp;

	unless (/\A\"SUID\"/) {

		# Save the edge between two entries.
		my $interaction;

		# Save the type of interaction between the two entries.
		my $interactionType;

		my $line = $_;
		
		# Save the author entry. There are really anoying unicode characters 
		# and even a questionmark in the names?!
		$line =~ m/\w(\w\w[a-zA-Z'\- \p{L}?]+, [a-zA-Z.\-\p{L}]+ et al\.\([0-9]+\)\")/;

		my $author = $1;
	
		# Remove the author entry.
		$line =~ s/\w[a-zA-Z'\- \p{L}?]+, [a-zA-Z.\-\p{L}]+ et al\.\([0-9]+\)\"//;
		# Get rid of the beginning double quote sign.
		$line =~ s/","/",/;

		# Save the content of each line.
		(my $dummy1, my $dummy3, my $dummy4, my $dummy5, $interactionType, my $dummy6, 
		 	$interaction, my @dummy) = split /,/, $line;

		# Remove quotes.
		$interaction =~ s/\"//g;

		# Split the interaction into the two involved entries.
		my @entries = split / /, $interaction;
		my $entry1 = $entries[0];
		my $entry2 = $entries[2];

		# Save the entries in the results or extend interactions for 
		# existing entries.

		# Save the result for entry1.
		if ($results{$entry1}) {
			$results{$entry1}->{$entry2}=$interactionType;
		} else {
			$results{$entry1}={ ($entry2 => $interactionType) };
		}

		# Save the result for entry2.
		if ($results{$entry2}) {
			$results{$entry2}->{$entry1}=$interactionType;
		} else {
			$results{$entry2}={ ($entry1 => $interactionType) };
		}
	}
}

close $fh;

####################
# List all vs all 


########################################
# Subroutines:

####################
# Print out error message for missing command line argument.
sub argumentError {
	my $missingArg = shift;
    	warn "Error \"--$missingArg\": Argument not initialised.\n";
	return 1;
}

