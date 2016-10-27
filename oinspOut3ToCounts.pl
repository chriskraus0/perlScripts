#! /usr/bin/perl

################################################################################
# This script goes through a Ortho Inspector output tsv table (format 3) counts
# each paralog and ortholog and displays it as total numbers per species.
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
		. "--oinsp3Tsv\t\tThis obligatory option gives the path and name of the\n"
		. "\t\t\tOrtho Inspector output (format 3; tsv table).\n\n"
		. "--outputTsv\t\tThis option should hold the path and name of the count table.\n\n"
		. "--geneName\t\tThis option should hold the initial gene-ID or gene-Name to query\n"
		. "\t\t\tOrtho Inspector.\n\n";

####################
# USAGE message:
my $usageMsg = "USAGE: ./oinspOut3ToCounts.pl --oinsp3Tsv=\'<FILE>\' --outputTsv=\'<FILE>\' --geneName=\'<GeneID|GeneName>\'\n\n"
		. "$helpMsg";

die "$usageMsg" unless (@ARGV == 3);

####################
# Get working directory and move to that directory.
my $dir = getcwd;
chdir $dir;

####################
# Read all parameters from command line options.

my $oinsp3Tsv;
my $outputTsv;
my $geneName;

GetOptions ("oinsp3Tsv=s" => \$oinsp3Tsv,
		"outputTsv=s" => \$outputTsv,
		"geneName=s" => \$geneName)
or die("Error in command line arguments.\n". "$usageMsg");

# Catch arguments not initialized errors:
die "Error: option \"--oinsp3Tsv\" was not given\n" unless ($oinsp3Tsv);
die "Error: option \"--queryBatch\" was not given\n" unless ($outputTsv);
die "Error: option \"--geneName\" was not given\n" unless ($geneName);

####################
# Read Ortho Inspector output tsv table (format 3) and retrieve all orthologs (and paralogs).

# Save all the orthologs/inparalogs in form of a hash.
my %orthologRes;

# Read the tsv file.
open my $fh, "<", $oinsp3Tsv or die "Error: $oinsp3Tsv: $!\n";

while (<$fh>) {
	chomp;
	(my $taxID, my $relation, my @orthologNspeices) = split /\t/;
	my @orthologs  = map {
		if (/\A\w\w\w\|/) {
			$_;
		} else {
			();
		} 
		} @orthologNspeices;
	
	foreach my $entry (@orthologs) {
		(my $species, my $ortholog) = split /\|/, $entry;
		if ($orthologRes{$species}) {
			$orthologRes{$species}->{$ortholog} = 1;
		} else {
			$orthologRes{$species} = { ($ortholog => 1) };
		}
	} 
}

close $fh;

####################
# Print results.

# Save evaluated results in hash.
my %evOrthoRes;

# Initialize result hash.
$evOrthoRes{'EBR'} = 0;
$evOrthoRes{'RCU'} = 0;	
$evOrthoRes{'RCT'} = 0;	
$evOrthoRes{'TSP'} = 0;	
$evOrthoRes{'GOR'} = 0;	
$evOrthoRes{'BMA'} = 0;	
$evOrthoRes{'LOA'} = 0;	
$evOrthoRes{'DIM'} = 0;	
$evOrthoRes{'ASU'} = 0;	
$evOrthoRes{'BUX'} = 0;	
$evOrthoRes{'MHA'} = 0;	
$evOrthoRes{'CEL'} = 0;	
$evOrthoRes{'CBR'} = 0;	
$evOrthoRes{'CRE'} = 0;	
$evOrthoRes{'CAN'} = 0;	
$evOrthoRes{'PPA'} = 0;	
$evOrthoRes{'HDU'} = 0;	
$evOrthoRes{'TCA'} = 0;	
$evOrthoRes{'DME'} = 0;	
$evOrthoRes{'SMA'} = 0;	
$evOrthoRes{'TUR'} = 0;	
$evOrthoRes{'DPU'} = 0;	
$evOrthoRes{'API'} = 0;	
$evOrthoRes{'CCA'} = 0;	
$evOrthoRes{'SPU'} = 0;	
$evOrthoRes{'BFL'} = 0;	
$evOrthoRes{'HSA'} = 0;


# Evaluate results.

foreach my $species (sort keys %orthologRes) {
	my $count = 0;
	foreach my $ortholog (sort keys %{ $orthologRes{$species} }) {
		$count += $orthologRes{$species}->{$ortholog};
	}
	if ($evOrthoRes{$species}) {
		$evOrthoRes{$species} += $count;
	} else {
		$evOrthoRes{$species} = $count;
	}
}


# Print evaluated results.

open my $ofh, ">", $outputTsv or die "Error: $outputTsv: $!\n";

print $ofh "$geneName\n";

print $ofh "EBR\t",
		"RCU\t",	
		"RCT\t",	
		"TSP\t",	
		"GOR\t",	
		"BMA\t",	
		"LOA\t",	
		"DIM\t",	
		"ASU\t",	
		"BUX\t",	
		"MHA\t",	
		"CEL\t",	
		"CBR\t",	
		"CRE\t",	
		"CAN\t",	
		"PPA\t",	
		"HDU\t",	
		"TCA\t",	
		"DME\t",	
		"SMA\t",	
		"TUR\t",	
		"DPU\t",	
		"API\t",	
		"CCA\t",	
		"SPU\t",	
		"BFL\t",	
		"HSA\n";

print $ofh "$evOrthoRes{'EBR'}\t",
		"$evOrthoRes{'RCU'}\t",	
		"$evOrthoRes{'RCT'}\t",	
		"$evOrthoRes{'TSP'}\t",	
		"$evOrthoRes{'GOR'}\t",	
		"$evOrthoRes{'BMA'}\t",	
		"$evOrthoRes{'LOA'}\t",	
		"$evOrthoRes{'DIM'}\t",	
		"$evOrthoRes{'ASU'}\t",	
		"$evOrthoRes{'BUX'}\t",	
		"$evOrthoRes{'MHA'}\t",	
		"$evOrthoRes{'CEL'}\t",	
		"$evOrthoRes{'CBR'}\t",	
		"$evOrthoRes{'CRE'}\t",	
		"$evOrthoRes{'CAN'}\t",	
		"$evOrthoRes{'PPA'}\t",	
		"$evOrthoRes{'HDU'}\t",	
		"$evOrthoRes{'TCA'}\t",	
		"$evOrthoRes{'DME'}\t",	
		"$evOrthoRes{'SMA'}\t",	
		"$evOrthoRes{'TUR'}\t",	
		"$evOrthoRes{'DPU'}\t",	
		"$evOrthoRes{'API'}\t",	
		"$evOrthoRes{'CCA'}\t",	
		"$evOrthoRes{'SPU'}\t",	
		"$evOrthoRes{'BFL'}\t",	
		"$evOrthoRes{'HSA'}\n";

close $ofh;
