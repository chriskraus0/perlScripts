#! /usr/bin/perl 

################################################################################
#./get_sequences.pl
#PURPOSE: 
#This scripts goes through a fasta file and extracts all entries which are 
#associated to a query batch file.
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
# USAGE message:
my $usageMsg = "USAGE: ./getFastaFile.pl --fasta=\'<FILE>\ --queryBatch=<FILE> --exactHeaders=<TRUE|FALSE>'\n";

die "$usageMsg" unless (@ARGV == 3);

####################
# Get working directory and move to that directory.
my $dir = getcwd;
chdir $dir;

####################
# Read all parameters from command line options.

my $fasta_file;
my $query_file;
my $exactHeader;

GetOptions ("fasta=s" => \$fasta_file,
		"queryBatch=s" => \$query_file,
		"exactHeaders=s" => \$exactHeader)
or die("Error in command line arguments.\n". "$usageMsg");

# Catch arguments not initialized errors:
die "Error: option \"--fasta\" was not given\n" unless ($fasta_file);
die "Error: option \"--queryBatch\" was not given\n" unless ($query_file);
die "Error: option \"--exactHeaders\" was not given\n" unless ($exactHeader);

# Catch wrongly initialized error:
die "Error: option \"--exactHeaders\" was \"$exactHeader\". This option excepts only \"TRUE\" or \"FALSE\".\n" 
	unless ($exactHeader eq "TRUE" || $exactHeader eq "FALSE");

####################
# Extract sequences.

open my $fh, "<", $query_file or die "Error: $query_file: $!\n";

my %headers;

while (<$fh>) {
	chomp;
	$headers{$_}="";
}

close $fh;

open $fh, "<", $fasta_file or die "Error: $fasta_file: $!\n";

my $current_header = "";
while (<$fh>) {
	chomp;
	if (/\A>/) {
		$current_header = "";
		foreach my $header (sort keys %headers) {
			if ($exactHeader eq "TRUE") {
				if ($_ eq $header) {
					$current_header = $_;
					last;
				}
			} else {
				if ($_ =~ /$header/) {
					$current_header = $_;
					last;
				}
			}
		}
	} elsif (/\A\w/) {
		if ($current_header) {
			if ($headers{$current_header}) {
				push @{ $headers{$current_header } }, $_;
			} else {
				$headers{$current_header} = [ $_ ];
			}
		}
	}
}

close $fh;

foreach my $header (sort keys %headers) {
	if ($headers{$header}) {
		print "$header\n";
		foreach (@{ $headers{$header} }) {
			print "$_\n";
		}
	}
}


