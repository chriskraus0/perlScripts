#! /usr/bin/perl

################################################################################
# samRefQueryGbk.pl
# This script goes line by line through a sam table extracts the names of all 
# reference sequences (column #3). These reference sequences should contain a
# pipe ('|') separated list with the following entries: 
# GeneID/Name|catergory:<TYPE>|chromosome:<NUM>|startpos|endpos
# The script will determine the startpos in respect to all included sequences/
# features and save them.
# Additionally this script will note the start position of each alignment query
# and will remember its start position (sam file column #4) the sequence 
# (column #11) and its length/endposition (length of entry in column #10).
# The findings will be formated in NCBI/EBI gene bank format (gbk).
################################################################################

####################
# Imports.

use utf8;
use 5.010;
use strict;
use warnings;
use Getopt::Long; #command line option module
use Cwd;	#module to provide information about current directory
use POSIX qw/floor/; #add method to floor decimal numbers.

####################
# Get working directory and move to that directory.
my $dir = getcwd;
chdir $dir;

####################
# USAGE message:
my $usageMsg = "USAGE: ./samRefQueryGbk.pl --samFile=<FILE> --fastaFile=<FILE>\n\n";


####################
# Catch argument errors.
warn ("\nWarning: All Arguments are required.\n\n") unless (@ARGV == 2);

####################
# Read all parameters from command line options.

my $samFile;
my $fastaFile;

GetOptions ("samFile=s" => \$samFile,
		"fastaFile=s" => \$fastaFile)
or die("Error in command line arguments.\n" . "$usageMsg");

my %parsedArgs = (samFile => \$samFile, fastaFile => \$fastaFile);

####################
# Catch argument errors.
my $missedArg = 0;
foreach my $arg (sort keys %parsedArgs) {
	$missedArg = &argumentError($arg) unless (${$parsedArgs{$arg}} eq "0" || ${$parsedArgs{$arg}});
}

die "Error: Necessary arguments not provided.\n\n$usageMsg\n" if ($missedArg);

####################
# Load information from SAM file.

open my $fh, "<", $samFile or die "Error: $samFile: $!\n";

my %refResult;
my @queryResult;

{
	my $firstPos = 0;
	my $lastPos = 0;

	while (<$fh>) {
		chomp;
		unless (/\A#/) {
			my @line = split /\t/;
			my @ref = split /\|/, $line[2];

			die "Error: $samFile: In reference header \"category\" was not provided\n" unless($ref[1] =~ /category/);
			die "Error: $samFile: In reference header \"chromosome\" was not provided\n" unless($ref[2] =~ /chromosome/);

			$ref[1] =~ s/\Acategory://g;
			$ref[2] =~ s/\Achromosome://g;
			
			$firstPos = $ref[3] unless ($firstPos);

			# Throw unsorted sam file error.
			die "Error: $samFile: current position $ref[3] is smaller than first position $firstPos in feature \"$line[2]\"\n"
				. "Must be a sorted sam file\n" if ($ref[3] < $firstPos);

			$lastPos = $ref[3] - $firstPos;
			my $refLen = $ref[4] - $ref[3];
			unless ($refResult{$line[2]}) {
				$refResult{$line[2]} = [ (@ref, $lastPos, $refLen + $lastPos) ];
			}
			push @queryResult, [ ($line[9], $line[3], $line[3] + length($line[9])) ];
		}
	}
}

close $fh;

####################
# Load information from Fasta file.

open $fh, "<", $fastaFile or die "Error: $fastaFile: $!\n";

my %refSeq;

{
	my $lastHeader = "";
	while (<$fh>) {
		chomp;
		if (/\A>/) {
			my $header = $_;

			# Check for Ensembl type of fasta file.
			die "Error: $fastaFile: header information not in ensembl format\n"
				. "must be \"><CHR NUM> <DNA>:chromosome chromsome:<GENOMEVERSION>:<CHR NUM>:<START POS>:<END POS>:<STRAND ORIENTATION>\"\n\n"
				. "Example: \">15 dna:chromosome chromosome:GRCz10:15:41353436:41376868:-1\"\n\n" 
				unless ($header =~ /\A>[0-9]+ [a-zA-Z]+:chromosome chromosome:[a-zA-Z]+[0-9]+:[0-9]+:[0-9]+:[0-9].*/);

			$refSeq{$header} = "";
			$lastHeader = $header;

		} elsif (/\A\w/) {
			if($refSeq{$lastHeader}) {
				$refSeq{$lastHeader} .= $_;
			} else {
				$refSeq{$lastHeader} = $_;
			}
		}
	}
}

close $fh;

####################
# Print result as gene bank file.

# Create FEATURES header line for gbk file.
print "FEATURES             Location/Color\n";

# Define colors for all encountered features.
my %featColor;
foreach my $feat (sort keys %refResult) {
	$featColor{$refResult{$feat}->[1]}="";
}

my $numColor = keys %featColor;

{
	my $counter = $numColor - 1;
	my ($r, $g, $b) = (0, 0, 0);
	foreach my $feat (sort keys %featColor) {
		if ($b < 127) { #bright red (255 0 0) is not allowed!
			$b = floor(0 + 255 / (($numColor - $counter) ));
		} else {
			$b = 0;
		}
		$g = floor(0 + 255 / (($numColor - $counter) )) if ($r < 127 && $b < 127);
		$r = floor(0 + 255 / (($numColor - $counter) )) if ($b < 127 && $g < 127);
		$counter --;
		$featColor{$feat} = [ ($r, $g, $b) ];
	}
}

# Print all features of the reference sequence.
foreach my $feat (sort keys %refResult) {
	my $bufferLen = 16 - length($refResult{$feat}->[1]);

	# Throw sequence-ID too long error.
	die "Error: Sequence-ID of \"$refResult{$feat}->[1]\" is longer than 15 characters\n" if ($bufferLen < 1);

	my $buffer;
	for (my $i = 0; $i < $bufferLen; $i ++) {
		$buffer .= " ";
	}


	printf("     %s%s%s..%s\n",$refResult{$feat}->[1],$buffer,$refResult{$feat}->[5],$refResult{$feat}->[6]);
	print "                     /color=@{$featColor{$refResult{$feat}->[1]}}\n";
}

# Print all query sequences.
foreach my $query (@queryResult) {
	my $bufferLen = 16 - length($query->[0]);

	# Throw sequence-ID too long error.
	die "Error: Sequence-ID of \"$query->[0]\" is longer than 15 characters\n" if ($bufferLen < 1);

	my $buffer;
	for (my $i = 0; $i < $bufferLen; $i ++) {
		$buffer .= " ";
	}

	printf ("     %s%s%s..%s\n",$query->[0],$buffer,$query->[1],$query->[2]);
	print "                     /color=255 0 0\n";
}

# Print the reference sequence.
foreach my $ref (sort keys %refSeq) {
	my @bases = split //, $refSeq{$ref};
	my @baseCount;
	foreach (@bases) {
		if ($_ eq "a" || $_ eq "A") {
			$baseCount[0] ++;
		} elsif ($_ eq "t" || $_ eq "T") {
			$baseCount[1] ++;
		} elsif ($_ eq "g" || $_ eq "G") {
			$baseCount[2] ++;
		} elsif ($_ eq "c" || $_ eq "C") {
			$baseCount[3] ++;
		}
	}
	print "BASE COUNT     $baseCount[0] a   $baseCount[3] c   $baseCount[2] g   $baseCount[1] t\n";
	print "ORIGIN";
	my $len = length($refSeq{$ref});
	for (my $i = 0; $i < $len; $i ++) {
		if ($i == 0) {
			printf("\n        %d %s",$i + 1, $bases[$i]);
		} elsif ( !($i % 60) ) {
			if ( $i + 1 < 10 ) {
				printf("\n        %d %s",$i + 1, $bases[$i]);
			} elsif ( $i + 1 < 100 ) {
				printf("\n       %d %s",$i + 1, $bases[$i]);
			} elsif ( $i + 1 < 1000 ) {
				printf("\n      %d %s",$i + 1, $bases[$i]);
			} elsif ( $i + 1 < 10000 ) {
				printf("\n     %d %s",$i + 1, $bases[$i]);
			} elsif ( $i + 1 < 100000 ) {
				printf("\n    %d %s",$i + 1, $bases[$i]);
			} elsif ( $i + 1 < 1000000 ) {
				printf("\n   %d %s",$i + 1, $bases[$i]);
			} elsif ( $i + 1 < 10000000 ) {
				printf("\n  %d %s",$i + 1, $bases[$i]);
			} elsif ( $i + 1 < 100000000 ) {
				printf("\n %d %s",$i + 1, $bases[$i]);
			} elsif ( $i + 1 < 1000000000 ) {
				printf("\n%d %s",$i + 1, $bases[$i]);
			}
		} elsif ($i % 60 && !(($i + 1) % 10) ) {
			print "$bases[$i] ";
		} elsif ($i % 60 && ($i + 1) % 10) {
			print $bases[$i];
		}
	}
	print "\n//\n";
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
