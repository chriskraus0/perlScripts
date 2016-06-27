#! /usr/bin/perl 

################################################################################
# This perl script goes through a phylipp file (*.phy) extracts the alignment
# and parses the result as an axt file (*.axt).
################################################################################

####################
# Imports.
use utf8;
use 5.010;
use strict;
use warnings;

# Import command line option module.
use Getopt::Long; 

# Import module to provide information about current directory.
use Cwd;

####################
# Get working directory and move to that directory.
my $dir = getcwd;
chdir $dir;

####################
#USAGE message:
my $usageMsg = "USAGE: ./getFastaByCoor.pl --phyFile=<FILE>\n"
		. "For help type $0 --help\n";


####################
#HELP message:
my $helpMsg = "NAME\n\n" 
		. "\t $0 - The aim of this script is to walk through a phylipp file\n"
		. "\t and extract alignment information. Output will be in axt format.\n\n"
		
		. "$usageMsg"

		. "ATTENTION\n"
		. "\tCommand line option is required.\n\n"

		. "OPTIONS\n"

		. "\t--help\tprints this help message\n\n"

		. "\t --phyFile=<FILE>\tInput of the provided phylipp file\n"
		. "\t\t\t which should be searched.\n\n"

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

my $phyFile;

GetOptions ("phyFile=s" => \$phyFile)
or die("Error in command line arguments.\n" . "$usageMsg");

my %parsedArgs = (phyFile => \$phyFile);

####################
# Catch argument errors.
my $missedArg = 0;
foreach my $arg (sort keys %parsedArgs) {
	$missedArg = &argumentError($arg) unless (${$parsedArgs{$arg}} eq "0" || ${$parsedArgs{$arg}});
}

die "Error: Necessary arguments not provided.\n\n$usageMsg\n" if ($missedArg);

####################
# Read phylipp file and extract alignment information.

# The hash %align will hold the header information and the relevant sequences.
my %align;

open my $fh, "<", $phyFile or die "Error: $!\n";

while (<$fh>) {
	chomp;
	unless (/\A [0-9]+ [0-9]+/) {
		my $line = $_;
		$line =~ m/\A(\S+)\s+([ATGCatgc-]+)/;
		my $header = $1;
		my $sequence = $2;
		$align{$header}=$sequence;
	}
}

close $fh;

####################
# Write the results to standard output.

# The string variable "parseHeader" will hold the parsed header information for 
# the axt file format.

my $parseHeader = "";

my @headers = sort keys %align;

foreach my $header (@headers) {
	if ($parseHeader) {
		$parseHeader .= "_VS_$header";
	} else {
		$parseHeader = $header;
	}
}

# Print header line for axt file.
print "$parseHeader\n";

# Print all sequences.
foreach my $header (sort keys %align) {
	print "$align{$header}\n";
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
