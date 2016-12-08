#! /usr/bin/perl


################################################################################
# This perl script goes through a blasttable (output format 6) and extracts the 
# first pre-defined number of homologs which share a common pattern and have the 
# hightest bit scores. 
#################################################################################

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
my $usageMsg = "USAGE: ./getFirstBestBlastHits.pl --blastFile=<FILE> --pattern=<REGEX> --exactHit=<TRUE|FALSE> --numberOfHits=<NUM>\n";

####################
# Catch argument errors.
warn ("\nWarning: All Arguments are required.\n\n") unless (@ARGV == 4);

####################
# Read all parameters from command line options.

my $blastFile;
my $sPattern;
my $exactHit;
my $hitNumber;

GetOptions ("blastFile=s" => \$blastFile,
		"pattern=s" => \$sPattern,
		"exactHit=s" => \$exactHit,
		"numberOfHits=i" => \$hitNumber)
or die("Error in command line arguments.\n" . "$usageMsg");

my %parsedArgs = (blastFile => \$blastFile, pattern => \$sPattern, exactHit => \$exactHit, numberOfHits => \$hitNumber);

####################
# Catch argument errors.
my $missedArg = 0;
foreach my $arg (sort keys %parsedArgs) {
	$missedArg = &argumentError($arg) unless (${$parsedArgs{$arg}} eq "0" || ${$parsedArgs{$arg}});
}

die "Error: Necessary arguments not provided.\n\n$usageMsg\n" if ($missedArg);

####################
# Catch user error concerning the exactHit option.

die "Error: In option \"--exactHit\" the value \"$exactHit\" is not appropriate.\n"
	. "It must be all uppercase \"TRUE\" or \"FALSE\".\n" . $usageMsg 
	unless ($exactHit eq "TRUE" || $exactHit eq "FALSE");

warn "Warning: Are you sure there are this many query hits per subject? Option \"--numberOfHits\": \"$hitNumber\"\n" 
	if ($hitNumber > 20);

####################
# Test the sharedPattern (sPattern).
warn "Warning: the option \"--pattern\" contains a pipe-character (\"|\"): \"$sPattern\"" 
	. "This is a REGEX operation an can lead to unexpected results, if you are not aware of this." 
	if ($exactHit eq "FALSE" && $sPattern =~ m/\|/);


warn "Warning: the option \"--pattern\" contain an alternative character set (\"[]\"): \"$sPattern\"" 
	. "This is a REGEX operation an can lead to unexpected results, if you are not aware of this." 
	if ($exactHit eq "FALSE" && ($sPattern =~ m/\[/ || $sPattern =~ m/\]/));


die "Warning: the option \"--pattern\" contain a group set (\"()\"): \"$sPattern\"" 
	. "This is not allowed in this REGEX operation." 
	if ($exactHit eq "FALSE" && ($sPattern =~ m/\(/ || $sPattern =~ m/\)/));


die "Warning: the option \"--pattern\" contain a specific multiplier set (\"{}\"): \"$sPattern\"" 
	. "This is not allowed in this REGEX operation." 
	if ($exactHit eq "FALSE" && ($sPattern =~ m/\{/ || $sPattern =~ m/\}/));

warn "Warning: the option \"--pattern\" contains multipliers (\"+*\"): \"$sPattern\"" 
	. "This is a REGEX operation an can lead to unexpected results, if you are not aware of this." 
	if ($exactHit eq "FALSE" && ( $sPattern =~ m/\+/ || $sPattern =~ m/\*/ ));

warn "Warning: the option \"--pattern\" contains replacements (\".?\"): \"$sPattern\"" 
	. "This is a REGEX operation an can lead to unexpected results, if you are not aware of this." 
	if ($exactHit eq "FALSE" && ( $sPattern =~ m/\./ || $sPattern =~ m/\?/ ));

warn "Warning: the option \"--pattern\" contains start or end character (\"^{$}\"): \"$sPattern\"" 
	. "This is a REGEX operation an can lead to unexpected results, if you are not aware of this." 
	if ($exactHit eq "FALSE" && ( $sPattern =~ m/\^/ || $sPattern =~ m/\$/ ));

warn "Warning: the option \"--pattern\" contains a backslash character (\"\\\"): \"$sPattern\"" 
	. "This is a REGEX operation an can lead to unexpected results, if you are not aware of this." 
	if ($exactHit eq "FALSE" && $sPattern =~ m/\\/);

####################
# Open blast table file and search for the pattern.

# Save results to a hash.
my %res;

open my $fh, "<", $blastFile or die "Error: $!\n";

# Save results per line.
my %currHit;
my $lastQuery;

while (<$fh>) {
	chomp;
	(my $query, my $subject, my $percent, my $length, 
	 my $mismatch, my $gapopen, my $qStart, my $qEnd, 
	 my $sStart, my $sEnd, my $eValue, my $bitScore) = split /\t/;

	# Initialize $lastQuery.
	$lastQuery = $query if (!$lastQuery);

	# If the $pattern is exactly the same string as $subject OR a substring.
	if ($exactHit eq "TRUE" 
			&& ($query eq $lastQuery || !$lastQuery)
			&& ($subject eq $sPattern || !(index ($subject, $sPattern) == -1) )) {
		# If the number of hits is smaller than the pre-defined value add more hits.
		if (keys %currHit < $hitNumber) {
			$currHit{$bitScore}=$subject;
		} elsif (keys %currHit >= $hitNumber) {
			# Sort all values of the hash by decreasing numeric order.
			my @hits = sort {$b <=> $a} keys %currHit;

			# If the current bitScore is greater than the biggest value 
			# remove the key and value of the lowest value from the hash
			# %currHit.
			if ($hits[0] < $bitScore) {
				# Delete smalles value in the hash.
				delete $currHit{$hits[$#hits]};
				$currHit{$bitScore} = $subject;
			}

		}
	} 
	
	# If regex is used.
	elsif ($exactHit eq "FALSE" 
			&& ($query eq $lastQuery || !$lastQuery)
			&& $subject=~/$sPattern/) {
		# If the number of hits is smaller than the pre-defined value add more hits.
		if (keys %currHit < $hitNumber) {
			$currHit{$bitScore}=$subject;
		} elsif (keys %currHit >= $hitNumber) {
			# Sort all values of the hash by decreasing numeric order.
			my @hits = sort {$b <=> $a} keys %currHit;

			# If the current bitScore is greater than the biggest value 
			# remove the key and value of the lowest value from the hash
			# %currHit.
			if ($hits[0] < $bitScore) {
				# Delete smalles value in the hash.
				delete $currHit{$hits[$#hits]};
				$currHit{$bitScore} = $subject;
			}

		}
	}

	# Check the query we are currently working on.
	if ($lastQuery ne $query) {
		# Write the results to the results hash.
		$res{$lastQuery}=[ (sort values %currHit) ];
		# Update the $lastQuery.
		$lastQuery = $query ;
		# Delete the currHit hash. 
		undef %currHit;
	}
}

close $fh;

####################
# Print results.

#Print header line.
print "#queryGene";
for (my $i = 1; $i < ($hitNumber + 1); $i ++) {
	print "\tsubjectGene",$i;
}
print "\n";

#Print results.
foreach my $qGene (sort keys %res) {
	print $qGene;
		foreach my $sGene (@{ $res{$qGene} }) {
			print "\t",$sGene;
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


