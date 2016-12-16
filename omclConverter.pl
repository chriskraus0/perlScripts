#! /usr/bin/perl

################################################################################
# ./omclConverter.pl
# This perl script goes through a tsv file and transforms columns and rows
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
#USAGE message:
my $usageMsg = "USAGE: ./omclConverter.pl --omclTsv=<FILE> --name=<NAME>\n"
		. "For help type $0 --help\n";


####################
#HELP message:
my $helpMsg = "NAME\n\n" 
		. "\t $0 - The aim of this script is to walk through a tsv file\n"
		. "\t and exchange rows and columns in a specific order.\n\n"
		
		. "$usageMsg"

		. "ATTENTION\n"
		. "\tAll 2 command line options are required.\n\n"

		. "OPTIONS\n"

		. "\t--help\tprints this help message\n\n"

		. "\t --omclTsv=<FILE>\tInput of the provided tsv file\n"
		. "\t\t\t which should be searched.\n\n"

		. "\t --name=<NAME>\tProvided name pattern for the output.\n"
		. "\n";


####################
#Catch argument errors.
if (@ARGV == 1 && $ARGV[0] eq "--help") {
	print "$helpMsg";
	exit 0;
}

warn ("\nWarning: All Arguments are required.\n\n") unless (@ARGV == 2);


####################
#Read all parameters from command line options.

my $tsvFile;
my $name;

GetOptions ("omclTsv=s" => \$tsvFile,
	"name=s" => \$name)
or die("Error in command line arguments.\n" . "$usageMsg");

my %parsedArgs = (omclTsv => \$tsvFile, name => \$name);

####################
#Catch argument errors.
my $missedArg = 0;
foreach my $arg (sort keys %parsedArgs) {
	$missedArg = &argumentError($arg) unless (${$parsedArgs{$arg}} eq "0" || ${$parsedArgs{$arg}});
}

die "Error: Necessary arguments not provided.\n\n$usageMsg\n" if ($missedArg);

####################
# Read tsv file.

my %res;

open my $fh, "<", $tsvFile;

while (<$fh>) {
	chomp;
	(my $spec, my $num) = split /\t/;
	$res{$spec}=$num;
}	

close $fh;

####################
# Sort results and print output.

my $outFile = $name . ".cluster" . ".counts.tsv";

open my $ofh, ">", $outFile;

# Print query name.
print $ofh "$name\n";

# Print header line.
print $ofh "CEL\t";
print $ofh "CBR\t";
print $ofh "CRE\t";
print $ofh "CAN\t";
print $ofh "PPA\t";
print $ofh "MHA\t";
print $ofh "BUX\t";
print $ofh "ASU\t";
print $ofh "LOA\t";
print $ofh "DIM\t";
print $ofh "BMA\t";
print $ofh "EBR\t";
print $ofh "TSP\t";
print $ofh "RCU\t";
print $ofh "RCT\t";
print $ofh "GOR\t";
print $ofh "HDU\t";
print $ofh "API\t";
print $ofh "DPU\t";
print $ofh "TUR\t";
print $ofh "SMA\t";
print $ofh "TCA\t";
print $ofh "DME\t";
print $ofh "CCA\t";
print $ofh "SPU\t";
print $ofh "BFL\t";
print $ofh "HSA\n";

# Print values.
print $ofh $res{"CEL"},"\t";
print $ofh $res{"CBR"}, "\t";
print $ofh $res{"CRE"}, "\t";
print $ofh $res{"CAN"}, "\t";
print $ofh $res{"PPA"}, "\t";
print $ofh $res{"MHA"}, "\t";
print $ofh $res{"BUX"}, "\t";
print $ofh $res{"ASU"}, "\t";
print $ofh $res{"LOA"}, "\t";
print $ofh $res{"DIM"}, "\t";
print $ofh $res{"BMA"}, "\t";
print $ofh $res{"EBR"}, "\t";
print $ofh $res{"TSP"}, "\t";
print $ofh $res{"RCU"}, "\t";
print $ofh $res{"RCT"}, "\t";
print $ofh $res{"GOR"}, "\t";
print $ofh $res{"HDU"}, "\t";
print $ofh $res{"API"}, "\t";
print $ofh $res{"DPU"}, "\t";
print $ofh $res{"TUR"}, "\t";
print $ofh $res{"SMA"}, "\t";
print $ofh $res{"TCA"}, "\t";
print $ofh $res{"DME"}, "\t";
print $ofh $res{"CCA"}, "\t";
print $ofh $res{"SPU"}, "\t";
print $ofh $res{"BFL"}, "\t";
print $ofh $res{"HSA"}, "\n";

########################################
# Subroutines:

####################
# Print out error message for missing command line argument.
sub argumentError {
	my $missingArg = shift;
    	warn "Error \"--$missingArg\": Argument not initialised.\n";
	return 1;
}


