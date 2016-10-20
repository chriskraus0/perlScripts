#! /usr/bin/perl

################################################################################
# This script recieves an tsv file which contains in the first column target
# names and in the second column query names. It searches the tsv file for 3 
# different kinds of gene IDs: Flybase gene ID "FBgnXXXXXXX", 
# uniprot gene "UNIXXXXX" and wormbase gene "WBGeneXXXXXX".
# It prints a list of found "translated" header sequences.
################################################################################

####################
# Imports:
use warnings;
use strict;
use utf8;
use 5.010;
use Getopt::Long;
use Cwd;

####################
# Help message:
my $helpMsg = "HELP\n\n"
		. "--headerTsv\t\tThis option should lead to the path of a 2 column tsv file.\n"
		. "\t\t\tThe 2 column tsv file should include target sequence name in the first column.\n"
		. "\t\t\tIn the second column it should contain one of three IDs:\n"
		. "\t\t\t1.) Flybase gene ID \"FBgnXXXXXXX\"\n"
		. "\t\t\t2.) Wormbase gene ID \"WBGeneXXXXX\"\n"
		. "\t\t\t3.) Uniprot gene ID \"XXXXXXXX\"\n\n"
		. "--query\t\tThis option should hold the gene ID the user wants to query.\n"
		. "\t\t\tIt should be in either of the following formats:\n"
		. "\t\t\t1.) Flybase gene ID \"FBgnXXXXXXX\"\n"
		. "\t\t\t2.) Wormbase gene ID \"WBGeneXXXXX\"\n"
		. "\t\t\t3.) Uniprot gene ID \"UNIXXXXXXXX\"\n\n"
		. "Results will be printed to the standard output.\n\n";

####################
# USAGE message:
my $usageMsg = "USAGE: ./transformHeaders.pl --headerTsv=\'<FILE>\' --query=\'<geneID>\'\n\n"
		. "$helpMsg";

die "$usageMsg" unless (@ARGV == 2);

####################
# Get working directory and move to that directory.
my $dir = getcwd;
chdir $dir;

####################
# Read all parameters from command line options.

my $headerTsv;
my $query;

GetOptions ("headerTsv=s" => \$headerTsv,
		"query=s" => \$query)
or die("Error in command line arguments.\n". "$usageMsg");

# Catch arguments not initialized errors:
die "Error: option \"--headerTsv\" was not given\n" unless ($headerTsv);
die "Error: option \"--queryBatch\" was not given\n" unless ($query);

# Catch worng query format errors.
&checkQuery($query);

my @queryErrors;
@queryErrors = map {
	if (($_ =~ /\AWBGene[0-9]*\b/) || ($_ =~ /\AFBgn[0-9]*\b/) || ($_ =~ /\AUNI\w*\b/)) {
			0; 
		} else {
			$_;
		}
	} ($query);

for (@queryErrors) {
	die "error: \"$_\" is not a valid ID!\n" if ($_);
}

####################
# Convert gene IDs.
my $IDType = $query;

if ($IDType =~ /\AUNI/) {
	$IDType =~ s/\AUNI/sp\\\|/;
}

####################
# Initialize index and print output.

open my $fh, "<", $headerTsv or die "Error: $headerTsv: $!\n";

my $ortholog = $IDType;

# Read the file.
while (<$fh>) {
	chomp;
	my $line = $_;
	my @line = split /\t/;
	if ($line =~ /$ortholog/) {
		$IDType = $line[0];
		$IDType =~ s/\A>//g;
		last;
	}
}

close $fh;

$IDType =~ s/\A\w+\|//g;

print $IDType, "\n";

########################################
# Subroutines / functions.

####################
# Catch worng query format error.
sub checkQuery {
	my $val = shift;
	if ($val =~ />/ || $val =~ /</ || $val =~ /\|/ || $val =~ /\$/ || $val =~ /\^/ || $val =~ / /) {
		die "Error: --query: $val: Symbols as \">, <, \|, \$, \^\" and SPACE are not allowed!\n";
	}
}

