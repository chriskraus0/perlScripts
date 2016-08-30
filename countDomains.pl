#! /usr/bin/perl

################################################################################
# Go through hmm domtblout domain files and count the number of domains. Remember 
# the specific domain type and the start and stop position with respect to the 
# db sequence. Only use domains with an arbritary E-value.
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
my $usageMsg = "USAGE: ./countDomains.pl --domtblout=<PATTERN> --output=<FILE> --cutoff=<NUM>\n\n";
####################
#Catch argument errors.
die ("\nError: All Arguments are required.\n\n" . "$usageMsg") unless (@ARGV == 3);

####################
#Read all parameters from command line options.

my $domtblout;
my $output;
my $cutoff;

GetOptions ("domtblout=s" => \$domtblout,
	"output=s" => \$output,
	"cutoff=i" => \$cutoff)
or die("Error in command line arguments.\n" . "$usageMsg");

####################
# Read domtblout file and remember domain locations.

my @files = glob "*$domtblout" or die "Error: $domtblout: $!\n";

my %targetSeqs;

foreach my $file (@files) {

	open my $fh, "<", $file or die "Error: $file: $!\n";

	while (<$fh>) {
		chomp;
		unless (/\A#/) {
			my @line = split /\t/;
			my $eval = $line[6];
			if ($line[6] =~ /e/) {
				$line[6] =~ s/[0-9]+\.[0-9]+e-//;
			} 
			# If there is no exponent in this field this field is greater than e.g. E-05 and hence not interesting.
			# Hence, I give it a "dummy" zero.
			else {
				$line[6] = 0;
			}
			if ($line[6] >= $cutoff) {
				if($targetSeqs{$line[0]}) {
					push @{ $targetSeqs{$line[0]} }, [ ($line[3], $line[4], $eval, $line[6], $line[19], $line[20]) ];
				} else {
					$targetSeqs{$line[0]} = [ [ ($line[3], $line[4], $eval, $line[6], $line[19], $line[20]) ] ];
				}
			}
		}
	}
	close $fh;
}

####################
# Remove overlapping domains by E-value.

my %interRes;

{
	my @last = ();
	foreach my $seq (sort keys %targetSeqs) {
		foreach my $currDomain (@{ $targetSeqs{$seq} }) {
			my $done = 0;
			my $index = 0;
			foreach my $domain (@{ $targetSeqs{$seq} }) {
				if ($currDomain->[4] <= $domain->[5] && $currDomain->[5] >= $domain->[4] && !($currDomain->[4] == $domain->[4] && $currDomain->[5] == $domain->[5])) {
					if ($currDomain->[3] >= $domain->[3]) {
						if ($interRes{$seq}) {
							push @{ $interRes{$seq} }, [ ( @{ $currDomain } ) ];
						} else {
							$interRes{$seq} = [ [ ( @{ $currDomain } ) ] ];
						}
						$done = 1;
					} else {
						if ($interRes{$seq}) {
							push @{ $interRes{$seq} }, [ ( @{ $domain } ) ];
						} else {
							$interRes{$seq} = [ [ ( @{ $domain } ) ] ];
						}
						$done = 1;
					}
					splice @{ $targetSeqs{$seq} }, $index, 1;
				}
				$index ++;
			}
			if ($done) {
				next;
			} else {
				if ($interRes{$seq}) {
					push @{ $interRes{$seq} }, [ ( @{ $currDomain } ) ];
				} else {
					$interRes{$seq} = [ [ ( @{ $currDomain } ) ] ];
				}
			}
		}
	}
}

####################
# Count domains per sequence.

my %results;

foreach my $seq (sort keys %interRes) {
	foreach my $domain (@{ $interRes{$seq} }) {
		if ($results{$seq}) {
			$results{$seq}->[0] ++;
			push @{ $results{$seq} }, ($domain->[0], $domain->[2]);
		} else {
			$results{$seq} = [ (1, $domain->[0], $domain->[2]) ];
		}
	}
}

####################
# Save results as tsv.

open my $ofh, ">", $output or die "Error: $output: $!\n";

foreach my $seq (sort keys %results) {
	print $ofh "$seq\t$results{$seq}->[0]\t";
	shift @{ $results{$seq} };
	foreach (@{ $results{$seq} }) {
		print $ofh "$_\t";
	}
	print $ofh "\n";
}
