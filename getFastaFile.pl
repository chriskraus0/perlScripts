#! /usr/bin/perl 

################################################################################
#./getFastFile.pl
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
my $usageMsg = "USAGE: ./getFastaFile.pl --fasta=\'<FILE>\ --queryBatch=<FILE> --exactHeaders=<TRUE|FALSE> --exactOrder=<TRUE|FALSE>'\n";

die "$usageMsg" unless (@ARGV == 4);

####################
# Get working directory and move to that directory.
my $dir = getcwd;
chdir $dir;

####################
# Read all parameters from command line options.

my $fasta_file;
my $query_file;
my $exactHeader;
my $exactOrder;

GetOptions ("fasta=s" => \$fasta_file,
		"queryBatch=s" => \$query_file,
		"exactHeaders=s" => \$exactHeader,
		"exactOrder=s" => \$exactOrder)
or die("Error in command line arguments.\n". "$usageMsg");

# Catch arguments not initialized errors:
die "Error: option \"--fasta\" was not given\n" unless ($fasta_file);
die "Error: option \"--queryBatch\" was not given\n" unless ($query_file);
die "Error: option \"--exactHeaders\" was not given\n" unless ($exactHeader);
die "Error: option \"--exactOrder\" was not given\n" unless ($exactOrder);

# Catch wrongly initialized error:
die "Error: option \"--exactHeaders\" was \"$exactHeader\". This option excepts only \"TRUE\" or \"FALSE\".\n" 
	unless ($exactHeader eq "TRUE" || $exactHeader eq "FALSE");

die "Error: option \"--exactOrder\" was \"$exactOrder\". This option excepts only \"TRUE\" or \"FALSE\".\n" 
	unless ($exactOrder eq "TRUE" || $exactOrder eq "FALSE");
####################
# Extract sequences.

open my $fh, "<", $query_file or die "Error: $query_file: $!\n";

my %headers;
my @order;

while (<$fh>) {
	chomp;
	$headers{$_}=-1;
	push @order, $_;
}

close $fh;

open $fh, "<", $fasta_file or die "Error: $fasta_file: $!\n";

my $current_header = "";
my $fastaHeader = "";

while (<$fh>) {
	chomp;
	if (/\A>/) {
		$current_header = "";
		$fastaHeader = "";
		if ($exactHeader eq "TRUE") {
			if ($headers{$_} == -1) {
				$current_header = $_;
				$fastaHeader = $_;
			}
		} else {
			foreach my $header (keys %headers) {
				if ( !(index ($_, $header) == -1) || $_ =~ /$header/ ) {
					$fastaHeader = $header;
					$current_header = $_;
					last;
				}
			}
		}
	} elsif (/\A\w/) {
		if ($fastaHeader) {
			if ($headers{$fastaHeader} == -1) {
				$headers{$fastaHeader} = [ ($current_header, $_) ];
			} else {
				push @{ $headers{$fastaHeader} }, ($_);
			}
		}
	}
}

close $fh;

if ($exactOrder eq "TRUE") {
	foreach my $header (@order) {
		if ($headers{$header}) {
			foreach (@{ $headers{$header} }) {
				print "$_\n";
			}
		}
	}
} else {
	foreach my $header (sort keys %headers) {
		if ($headers{$header}) {
			foreach (@{ $headers{$header} }) {
				print "$_\n";
			}
		}
	}
}

