#! /usr/bin/perl

################################################################################
# This perl script randomizes a list of words for a defined number of resulting
# words.
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
my $usageMsg = "USAGE: $0 --list=<FILE> --maxWords=<NUM>\n"
		. "For help type $0 --help\n";


####################
#HELP message:
my $helpMsg = "NAME\n\n" 
		. "\t $0 - The aim of this script to read a newline separated list of words\n"
		. "\t and create a randomized sublist with a predefined number resulting words.\n\n"
		
		. "$usageMsg"

		. "ATTENTION\n"
		. "\tAll 2 command line options are required.\n\n"

		. "OPTIONS\n"

		. "\t--help\tprints this help message\n\n"

		. "\t --list=<FILE>\tInput of the provided word list\n\n"

		. "\t --maxWords=<NUM>\tNumber of resulting words.\n\n"

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

my $list;
my $max;

GetOptions ("list=s" => \$list,
	"maxWords=i" => \$max)
or die("Error in command line arguments.\n" . "$usageMsg");

my %parsedArgs = (list => \$list, maxWords => \$max);

####################
#Catch argument errors.
my $missedArg = 0;
foreach my $arg (sort keys %parsedArgs) {
	$missedArg = &argumentError($arg) unless (${$parsedArgs{$arg}} eq "0" || ${$parsedArgs{$arg}});
}

die "Error: Necessary arguments not provided.\n\n$usageMsg\n" if ($missedArg);


####################
# Read the list and generate a new sublist.

# Array holds the words in original order.
my @list; 

# Keep track of the number of read lines.
my $listLen;

open my $fh, "<", $list or die "Error: $list: $!\n";

while(<$fh>) {
	chomp; 
	push @list, $_;
	$listLen ++;
} 

close $fh;

# Throw a warning if length of sublist is longer than 
# original length.

if ($max >= $listLen) {
	warn "Warning: option \"--maxWords\" is greater or equal to the size of the word list.\n"
		. "Word List: $listLen words\n"
		. "\"--maxWords\": $max\n\n";
}
	
# Iterate over all remaining entries and select new words.
for (my $i = 0; $i < $max; $i++) { 
	my $randNum = int(rand($listLen));
	print $list[$randNum],"\n";
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

