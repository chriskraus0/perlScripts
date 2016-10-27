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
		. "\t\t\tOrtho Inspector.\n"
		. "--headerIndex\t\tThis option holds the path to the gene name index file (2 column tsv)\n\n";

####################
# USAGE message:
my $usageMsg = "USAGE: ./oinspOut3ToCounts.pl --oinsp3Tsv=\'<FILE>\' --outputTsv=\'<FILE>\' --geneName=\'<GeneID|GeneName>\' --headerIndex=\'<FILE>\'\n\n"
		. "$helpMsg";

die "$usageMsg" unless (@ARGV == 4);

####################
# Get working directory and move to that directory.
my $dir = getcwd;
chdir $dir;

####################
# Read all parameters from command line options.

my $oinsp3Tsv;
my $outputTsv;
my $geneName;
my $headerIndex;

GetOptions ("oinsp3Tsv=s" => \$oinsp3Tsv,
		"outputTsv=s" => \$outputTsv,
		"geneName=s" => \$geneName,
		"headerIndex=s" => \$headerIndex)
or die("Error in command line arguments.\n". "$usageMsg");

# Catch arguments not initialized errors:
die "Error: option \"--oinsp3Tsv\" was not given\n" unless ($oinsp3Tsv);
die "Error: option \"--queryBatch\" was not given\n" unless ($outputTsv);
die "Error: option \"--geneName\" was not given\n" unless ($geneName);
die "Error: option \"--headerIndex\" was not given\n" unless ($headerIndex);

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
# Load header index information.

# Save header index in hash.
my %orthologGeneRes;

open $fh, "<", $headerIndex or die "Error: $headerIndex: $!\n";

while (<$fh>) {
	chomp;
	if (/\A>/) {
		(my $oinspHeader, my $origHeader) = split /\t/;
		(my $headerSpecies, my $dummy) = split /\|/, $oinspHeader; 

		$headerSpecies =~ s/\A>//;
		$oinspHeader =~ s/\A>\w\w\w\|//;
		$origHeader =~ s/\A>\w\w\w\|//;

		foreach my $species (sort keys %orthologRes) {
			if ($headerSpecies eq $species) {
				foreach my $ortholog (sort keys %{ $orthologRes{$species} }) {
					if ($ortholog eq $oinspHeader) {
						if ($orthologGeneRes{$species}) {
							$orthologGeneRes{$species}->{$origHeader} = 1;
							last;
						} else {
							$orthologGeneRes{$species} = { ($origHeader => 1) };
							last;
						}
					}
				}
				last;
			}
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

foreach my $species (sort keys %orthologGeneRes) {
	my $count = 0;
	foreach my $ortholog (sort keys %{ $orthologGeneRes{$species} }) {
		$count += $orthologGeneRes{$species}->{$ortholog};
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

print $ofh "CEL\t",
		"CBR\t",	
		"CRE\t",	
		"CAN\t",	
		"PPA\t",	
		"MHA\t",	
		"BUX\t",	
		"ASU\t",	
		"LOA\t",	
		"DIM\t",	
		"BMA\t",	
		"EBR\t",	
		"TSP\t",	
		"RCU\t",	
		"RCT\t",	
		"GOR\t",	
		"HDU\t",	
		"API\t",	
		"DPU\t",	
		"TUR\t",	
		"SMA\t",	
		"TCA\t",	
		"DME\t",	
		"CCA\t",	
		"SPU\t",	
		"BFL\t",	
		"HSA\n";

print $ofh "$evOrthoRes{'CEL'}\t",
		"$evOrthoRes{'CBR'}\t",	
		"$evOrthoRes{'CRE'}\t",	
		"$evOrthoRes{'CAN'}\t",	
		"$evOrthoRes{'PPA'}\t",	
		"$evOrthoRes{'MHA'}\t",	
		"$evOrthoRes{'BUX'}\t",	
		"$evOrthoRes{'ASU'}\t",	
		"$evOrthoRes{'LOA'}\t",	
		"$evOrthoRes{'DIM'}\t",	
		"$evOrthoRes{'BMA'}\t",	
		"$evOrthoRes{'EBR'}\t",	
		"$evOrthoRes{'TSP'}\t",	
		"$evOrthoRes{'RCU'}\t",	
		"$evOrthoRes{'RCT'}\t",	
		"$evOrthoRes{'GOR'}\t",	
		"$evOrthoRes{'HDU'}\t",	
		"$evOrthoRes{'API'}\t",	
		"$evOrthoRes{'DPU'}\t",	
		"$evOrthoRes{'TUR'}\t",	
		"$evOrthoRes{'SMA'}\t",	
		"$evOrthoRes{'TCA'}\t",	
		"$evOrthoRes{'DME'}\t",	
		"$evOrthoRes{'CCA'}\t",	
		"$evOrthoRes{'SPU'}\t",	
		"$evOrthoRes{'BFL'}\t",	
		"$evOrthoRes{'HSA'}\n";

close $ofh;
