#! /usr/bin/perl

################################################################################
# This perl script goes through a dictionary and retrieves the morphemes and 
# lexemes. Next it matches calculated splits with the dictionary morpheme entries.
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
my $usageMsg = "USAGE: $0 --dict=<FILE> --morphList=<FILE>\n"
		. "For help type $0 --help\n";


####################
#HELP message:
my $helpMsg = "NAME\n\n" 
		. "\t $0 - The aim of this script is to walk through a dictionary\n"
		. "\t and matches all morphemes with the generated splits.\n\n"
		
		. "$usageMsg"

		. "ATTENTION\n"
		. "\tAll 2 command line options are required.\n\n"

		. "OPTIONS\n"

		. "\t--help\tprints this help message\n\n"

		. "\t --dict=<FILE>\tInput of the provided dictionary\n\n"

		. "\t --morphList=<FILE>\tProvided list which\n"
		. "\t\t\t includes all generated lexemes and morphemes\n"
		. "\t\t\t for a text.\n"

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

my $dict;
my $morphList;

GetOptions ("dict=s" => \$dict,
	"morphList=s" => \$morphList)
or die("Error in command line arguments.\n" . "$usageMsg");

my %parsedArgs = (dict => \$dict, morphList => \$morphList);

####################
#Catch argument errors.
my $missedArg = 0;
foreach my $arg (sort keys %parsedArgs) {
	$missedArg = &argumentError($arg) unless (${$parsedArgs{$arg}} eq "0" || ${$parsedArgs{$arg}});
}

die "Error: Necessary arguments not provided.\n\n$usageMsg\n" if ($missedArg);


####################
# Read the dictionary.

# Save the results in a hash.
my %dict;

open my $fh, "<", $dict or die "Error: $dict: $!\n";

while (<$fh>) {
	chomp;

	# Word attributes.
	my $gender;
	my $isAdjective;
	my $isAdverb;
	my $isVerb;
	my $isNoun;
	my $isPlural;
	my $isPreposition;
	my $isNonSplit = "split";

	# Word types.
	my @verb;
	my @adjective;
	my @adverb;
	my @noun;
	my @prep;

	my @line = split /\+/;

	# Is it a male plural noun?
	if ($line[$#line] eq "m.pl") {
		$gender = pop @line;

		# Is it a non-split word?
		if ($line[$#line] eq "-") { 
			pop @line;
			$isNonSplit = "nonSplit";
		}
		@noun = @line;

		my $fullWord = join("|", @noun);
		$dict{$fullWord} = [ ( [@noun], $isNonSplit, $gender) ];
	} 

	# Is it a female plural noun?
	elsif ($line[$#line] eq "m.pl") {
		$gender = pop @line;
		# Is it a non-split word?
		if ($line[$#line] eq "-") { 
			pop @line;
			$isNonSplit = "nonSplit";
		}
		@noun = @line;
		my $fullWord = join("|", @noun);
		$dict{$fullWord} = [ ( [@noun], $isNonSplit, $gender) ];
	}
	
	# Is it a neutral plural noun?
	elsif ($line[$#line] eq "n.pl") {
		$gender = pop @line;
		# Is it a non-split word?
		if ($line[$#line] eq "-") { 
			pop @line;
			$isNonSplit = "nonSplit";
		}
		@noun = @line;
		my $fullWord = join("|", @noun);
		$dict{$fullWord} = [ ( [@noun], $isNonSplit, $gender) ];
	}

	# Is it male, female or neutral?
	elsif ($line[$#line] eq "m"
		|| $line[$#line] eq "f"
		|| $line[$#line] eq "n") {
		$gender = pop @line;

		# Is it a noun?
		if ($line[$#line] eq "n") {
			$isNoun = pop @line;
			# Is it a non-split word?
			if ($line[$#line] eq "-") { 
				pop @line;
				$isNonSplit = "nonSplit";
			}
			@noun = @line;
			my $fullWord = join("|", @noun);
			$dict{$fullWord} = [ ( [@noun], $isNonSplit, $gender) ];
		}

		# Is it an adjective?
		elsif ($line[$#line] eq "adj") {
			$isAdjective = pop @line;
			# Is it a non-split word?
			if ($line[$#line] eq "-") { 
				pop @line;
				$isNonSplit = "nonSplit";
			}
			@adjective = @line;
			my $fullWord = join("|", @adjective);
			$dict{$fullWord} = [ ( [@adjective], $isNonSplit, $gender) ];
		}

	} 

	# Is it an adjective?
	elsif ($line[$#line] eq "adj") {
		my $isAdjective = pop @line;
		# Is it a non-split word?
		if ($line[$#line] eq "-") { 
			pop @line;
			$isNonSplit = "nonSplit";
		}
		@adjective = @line;
		$gender = "X";
		my $fullWord = join("|", @adjective);
		$dict{$fullWord} = [ ( [@adjective], $isNonSplit, $gender) ];
	} 
	
	# Is it an adverb?
	elsif ($line[$#line] eq "adv") {
		my $isAdverb = pop @line;
		# Is it a non-split word?
		if ($line[$#line] eq "-") { 
			pop @line;
			$isNonSplit = "nonSplit";
		}
		@adverb = @line;
		$gender = "X";
		my $fullWord = join("|", @adverb);
		$dict{$fullWord} = [ ( [@adverb], $isNonSplit, $gender) ];
	} 
	
	# Is it a verb?
	elsif ($line[$#line] eq "v"
			|| $line[$#line] eq "-v") {
		my $isVerb = pop @line;
		# Is it a non-split word?
		if ($line[$#line] eq "-") { 
			pop @line;
			$isNonSplit = "nonSplit";
		}
		@verb = @line;
		$gender = "X";
		my $fullWord = join("|", @verb);
		$dict{$fullWord} = [ ( [@verb], $isNonSplit, $gender) ];
	} 
	# Is it a preposition?
	elsif ($line[$#line] eq "v"
			|| $line[$#line] eq "-v") {
		my $isPreposition = pop @line;
		# Is it a non-split word?
		if ($line[$#line] eq "-") { 
			pop @line;
			$isNonSplit = "nonSplit";
		}
		@prep = @line;
		$gender = "X";
		my $fullWord = join("|", @prep);
		$dict{$fullWord} = [ ( [@prep], $isNonSplit, $gender) ];
	} 
}

close $fh;

####################
# Read morphList.

# Save the results in a hash;
my %res;

open $fh, "<", $morphList or die "Error: $morphList; $!\n";

while (<$fh>) {
	if ($dict{$_}) {
		$res{$_} = $dict{$_};
	}
}

close $fh;

####################
# Write results.

# Write header line.
print "Match\tDictonaryEntry\tsplit/NonSplit\tGender\tMorphemes\n";

foreach my $entry (sort keys %res) {
	print "yes\t$entry";
	print "\t" . $res{$entry}->[1];
	print "\t" . $res{$entry}->[2];
	foreach my $morph (@{ $res{$entry}->[0] }) {
		print "\t" . "$morph";
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

