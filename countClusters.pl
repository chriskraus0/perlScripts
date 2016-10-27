#! /usr/bin/perl

################################################################################
# This script goes to a file with ortho MCL clusters and counts orthologs by 
# species.
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
		. "--clusterFile\t\tThis option defines the path and name of the ortho mcl cluster file\n\n"
		. "--outputTsv\t\tThis options defines the file name and path of the tsv output file\n\n";

####################
# USAGE message:
my $usageMsg = "USAGE: ./countClusters.pl --clusterFile=\'<FILE>\' --outputTsv=\'<FILE>\'\n\n"
		. "$helpMsg";

die "$usageMsg" unless (@ARGV == 2);

####################
# Get working directory and move to that directory.
my $dir = getcwd;
chdir $dir;

####################
# Read all parameters from command line options.

my $clusterFile;
my $outputTsv;

GetOptions ("clusterFile=s" => \$clusterFile,
		"outputTsv=s" => \$outputTsv)
or die("Error in command line arguments.\n". "$usageMsg");

# Catch arguments not initialized errors:
die "Error: option \"--headerTsv\" was not given\n" unless ($clusterFile);
die "Error: option \"--queryBatch\" was not given\n" unless ($outputTsv);

####################

my %clusters;

# Read clusters from file.
open my $fh, "<", $clusterFile or die "Error: $clusterFile: $!\n";

open my $ofh, ">", $outputTsv or die "Error: $outputTsv: $!\n";

while (<$fh>) {
	chomp;
	(my $clusterName, my $dummy, my @orthologs) = split / /;
	$clusterName =~ s/:\z//;
	
	my %counter;
	
	#initializing %counter
	$counter{'HSA'}= 0;#outgroups
	$counter{'CCA'}= 0; 
	$counter{'SPU'}= 0; 
	$counter{'BFL'}= 0;
	$counter{'DME'}= 0;
	$counter{'TCA'}= 0;
	$counter{'DPU'}= 0;
	$counter{'API'}= 0; 
	$counter{'SMA'}= 0; 
	$counter{'HDU'}= 0;
	$counter{'TUR'}= 0;

	$counter{'GOR'}= 0;#nematomorphs

	$counter{'RCT'}= 0;#cladeI
	$counter{'RCU'}= 0;
	$counter{'TSP'}= 0;

	$counter{'EBR'}= 0;#cladeII

	$counter{'ASU'}= 0;#cladeIII
	$counter{'LOA'}= 0;
	$counter{'BMA'}= 0;
	$counter{'DIM'}= 0;


	$counter{'MHA'}= 0;#cladeIV
	$counter{'BUX'}= 0; 

	
	$counter{'PPA'}= 0;#cladeV
	$counter{'CAN'}= 0; 
	$counter{'CBR'}= 0;
	$counter{'CEL'}= 0;
	$counter{'CRE'}= 0;

	foreach my $ortholog (@orthologs) {
		my @tag = split /\|/, $ortholog;
		$counter{$tag[0]} = $counter{$tag[0]} + 1;
	}
	
	print $ofh "$clusterName\t";
	print $ofh "$counter{'EBR'}\t",
		"$counter{'RCU'}\t",	
		"$counter{'RCT'}\t",	
		"$counter{'TSP'}\t",	
		"$counter{'GOR'}\t",	
		"$counter{'BMA'}\t",	
		"$counter{'LOA'}\t",	
		"$counter{'DIM'}\t",	
		"$counter{'ASU'}\t",	
		"$counter{'BUX'}\t",	
		"$counter{'MHA'}\t",	
		"$counter{'CEL'}\t",	
		"$counter{'CBR'}\t",	
		"$counter{'CRE'}\t",	
		"$counter{'CAN'}\t",	
		"$counter{'PPA'}\t",	
		"$counter{'HDU'}\t",	
		"$counter{'TCA'}\t",	
		"$counter{'DME'}\t",	
		"$counter{'SMA'}\t",	
		"$counter{'TUR'}\t",	
		"$counter{'DPU'}\t",	
		"$counter{'API'}\t",	
		"$counter{'CCA'}\t",	
		"$counter{'SPU'}\t",	
		"$counter{'BFL'}\t",	
		"$counter{'HSA'}\n";
	
}

close $fh;
close $ofh;
