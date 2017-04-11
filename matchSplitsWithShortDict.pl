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
my $usageMsg = "USAGE: $0 --dict=<FILE> --morphList=<FILE> --shiftBorder=<NUM>\n"
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
		. "\t\t\t for a text.\n\n"

		. "\t --shiftBorder=<HUM>\tIf non-exact machting is intened\n"
		. "\t\t\t this option allows a specific number of shifts to the\n"
		. "\t\t\t right and left border of occuring splits.\n"
		. "\t\t\t Insert \"0\" for exact matching.\n\n"

		. "\n";


####################
#Catch argument errors.
if (@ARGV == 1 && $ARGV[0] eq "--help") {
	print "$helpMsg";
	exit 0;
}

warn ("\nWarning: All Arguments are required.\n\n") unless (@ARGV == 3);


####################
#Read all parameters from command line options.

my $dict;
my $morphList;
my $shiftBorder;

GetOptions ("dict=s" => \$dict,
	"morphList=s" => \$morphList,
	"shiftBorder=i" => \$shiftBorder)
or die("Error in command line arguments.\n" . "$usageMsg");

my %parsedArgs = (dict => \$dict, morphList => \$morphList, 
	shiftBorder => \$shiftBorder);

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
	(my $word, my $split) = split /\t/;
	$dict{$word}=[ ( $split, "true" ) ];
}
close $fh;

####################
# Read morphList and compare and write results.

# Save results in a hash;
my %res;

# Write header line.
print "#Word\tDictionary\tQuery\tMatch\n";

open $fh, "<", $morphList or die "Error: $morphList; $!\n";

while (<$fh>) {
	chomp;
	my $line = $_;
	
	# decide which subroutine/function to use. 
	# Either exact, or non-exact matchting.
	if ($shiftBorder == 0) {
		&exactMatch(\%dict, $line);
	} else {
		&nonExactMatch(\%dict, $line, $shiftBorder);
	}
}

close $fh;

########################################
# Subroutines:

####################
# Print out error message for missing command line argument.
sub argumentError {
	my $missingArg = shift;
    	warn "Error \"--$missingArg\": Argument not initialised.\n";
	return 1;
}

####################
# Sub exactMatch.
# Test for exact matches between the dictionary and the read line.
sub exactMatch {
	# Get the arguments.
	my $dict = shift;
	my $line = shift;

	# Compare the dictionary entry and line and print the result.
	my $comp = $line;
	$comp =~ s/\|//;
	if ($$dict{$comp}) {
		if ($$dict{$comp}->[0] eq $line) {
			print "$comp\t$$dict{$comp}->[0]\t$line\t$$dict{$comp}->[1]\n";
		} elsif ($$dict{$comp}->[0] ne $line) {
			print "$comp\t$$dict{$comp}->[0]\t$line\tfalse\n";
		}
	} else {
		print "$comp\tNO ENTRY\t$line\tNO ENTRY\n";
	}
}

####################
# Sub isExactMatch.
# Subroutine which returns "1" for an exact match, "0" for not exact match
# and "-1" if the word is not part of the dictionary.
sub isExactMatch {
	# Get the arguments.
	my $dict = shift;
	my $line = shift;

	# Compare the dictionary entry and line and print the result.
	my $comp = $line;
	$comp =~ s/\|//;
	if ($$dict{$comp}) {
		if ($$dict{$comp}->[0] eq $line) {
			return 1;
		} elsif ($$dict{$comp}->[0] ne $line) {
			return 0;
		}
	} else {
			return -1;
	}
}

####################
# Sub nonExactMatch.
# Test for non-exact machtes between the dictionary and the read line.
sub nonExactMatch {
	##########	
	# Get the arguments.
	my $dict = shift;
	my $line = shift;
	my $shift = shift;
	
	##########	
	# Get a string which can be used to invoke the correct value in the %dict hash.
	my $comp = $line;
	$comp =~ s/\|//;

	my $borderPos = index ($line, "|");
	my $lineLen = length $line;

	##########	
	# Catch the problem of a border shift > than remaining chars.
	if ($borderPos + $shift > $lineLen - 1
		|| $borderPos - $shift < 0) {
		warn "Warning: Shifting the split for the word \""
			. $line 
			. "\" more than "
			. $shift
			. " positions is not possible."
			. " Shifting omitted.";
		# Do an exact match instead and return directly.
		&exactMatch(\$dict, $line);
		return 0;
	}
	
	##########	
	# Preprocess line for all possible border shifts.
	my @linesLeft;
	my @linesRight;
	my @processedLine;

	# Insert the border at the correct positions for the 
	# whole set of possible strings.
	for (my $i = 0; $i < $shift; $i ++) {
		
		# Shift the border to the left.
		$linesLeft[$i] = substr $comp, 0, ($borderPos - ($i + 1));
		$linesLeft[$i] .= "|";
		$linesLeft[$i] .= substr $comp, ($borderPos - ($i + 1));

		# Shift the border to the right.
		$linesRight[$i] = substr $comp, 0, ($borderPos + ($i + 1));
		$linesRight[$i] .= "|";
		$linesRight[$i] .= substr $comp, ($borderPos + ($i + 1));
	}

	##########	
	# Compare the dictionary entry and the line.
	
	# Save the results in a new array.
	my @res; 

	if ($$dict{$comp}) {
		# Test for exact match.
		my $isMatch = &isExactMatch($dict, $line);

		if ($isMatch == 1 || $isMatch == -1) {
			&exactMatch($dict, $line);
			return 0;
		}

		# Test the left-shifted strings.	
		foreach my $left (@linesLeft) {
			if ($$dict{$comp}->[0] eq $left) {
				push @res, [ ($comp, $$dict{$comp}->[0], $left, $$dict{$comp}->[1]) ];
			} 
		}
		# Test the right-shifted strings.	
		foreach my $right (@linesRight) {
			if ($$dict{$comp}->[0] eq $right) {
				push @res, [ ($comp, $$dict{$comp}->[0], $right, $$dict{$comp}->[1]) ];
			} 
		}
	} else {
		print "$comp\tNO ENTRY\t$line\tNO ENTRY\n";
	}

	##########
	# Print the results.
	my $resNum = @res;
	
	if ($resNum) {
		foreach my $res (@res) {
			print $res->[0] . "\t" . $res->[1] . "\t" . $res->[2] . "\t" . $res->[3] . "\n";
		}
	}
}
