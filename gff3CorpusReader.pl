#! /usr/bin/perl

################################################################################
#This scripts walks through genome annotation files of the gff3 format (mostly created
#as AUGUSTUS output, but any valid gff3 file can be used) and extracts appropriate
#sequences from one fasta file or a list of fasta files (should contain genomic
#information).
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
my $usageMsg = "USAGE: ./gff3CorpusReader.pl --gff3=<FILE> --targetList=<FILE> --fasta=\'<FILE,FILE,FILE...>\'"
		. "--upstream=<NUM> --downstream=<NUM>\n\n"
		. "For help type $0 --help\n";


####################
#HELP message:
my $helpMsg = "NAME\n\n" 
		. "\t $0 - The aim of this script is to walk through a gff3 file\n"
		. "\t and extracttarget sequences. Output will be in fasta format.\n"
		. "\t For each \"category\" (exon, intron, promotor etc.) the output.\n"
		. "\t fasta file will contain a separate sequence. Header information\n"
		. "\t represents gff3 annotation categories.\n\n"

		. "$usageMsg"

		. "ATTENTION\n"
		. "\tAll 5 command line options are required.\n\n"

		. "OPTIONS\n"

		. "\t--help\tprints this help message\n\n"

		. "\t--gff3=<FILE>\tThe location of the gff3 file (can include relative\n"
		. "\t\t\t and absolute path).\n\n"

		. "\t--targetList=<FILE>\tThe location of a tsv table file which contains\n"
		. "\t\t\t information about the target genes. The tsv table must include\n"
		. "\t\t\t the following fields in that specific order:\n"
		. "\t\t\t EnsemblGeneID\tChromsomeNumber\tStartPos\tStopPos\n"
		. "\t\t\t If any of these fields are missing or can not be found in the gff3\n"
		. "\t\t\t this will throw an error and the programme will terminate.\n\n"

		. "\t--fasta=\'<FILE,FILE,FILE,...>\'\t a single fasta file or a list\n"
		. "\t\t\t of fasta files providing the genomic information. For a single\n"
		. "\t\t\t file the name can be arbritary for a list of files each file\n"
		. "\t\t\t must comply the pattern \"chr1.fasta\", \"chr2.fasta\" etc.\n"
		. "\t\t\t If this is not this script will throw and error and terminate.\n\n"

		. "\t--upstream=<NUM>\tThe number of base pairs upstream from\n"
		. "\t\t\t the first exon. If <NUM> greater than 0 the upstream region will\n"
		. "\t\t\t be provided as separte fasta entry for that specific gene.\n"
		. "\t\t\t Default value is \"2000\"\n\n"
		
		. "\t--downstream=<NUM>\tThe number of base pairs downstream from\n"
		. "\t\t\t the last exon. If <NUM> greater than 0 the downstream region will\n"
		. "\t\t\t be provided as separte fasta entry for that specific gene.\n"
		. "\t\t\t Default value is \"2000\"\n\n"

		. "\n";

####################
#Catch argument errors.
if (@ARGV == 1 && $ARGV[0] eq "--help") {
	print "$helpMsg";
	exit 0;
}

warn ("\nWarning: All Arguments are required.\n\n") unless (@ARGV == 5);

####################
#Read all parameters from command line options.

my $gff3;
my $targetList;
my $fasta;
my $upstream;
my $downstream;

GetOptions ("gff3=s" => \$gff3,
	"targetList=s" => \$targetList,
	"fasta=s" => \$fasta,
	"upstream=i"   => \$upstream,
	"downstream=i" => \$downstream)
or die("Error in command line arguments.\n" . "$usageMsg");

my %parsedArgs = (gff3 => \$gff3, targetList => \$targetList, fasta => \$fasta, upstream => \$upstream, downstream => \$downstream);

####################
#Catch argument errors.
my $missedArg = 0;
foreach my $arg (sort keys %parsedArgs) {
	$missedArg = &argumentError($arg) unless (${$parsedArgs{$arg}} eq "0" || ${$parsedArgs{$arg}});
}

die "Error: Necessary arguments not provided.\n\n$usageMsg\n" if ($missedArg);

####################
# Catch error in fasta file list.
die ("Error in --regex option.\n"
. "--fasta must be the pattern \'FILE,FILE,...\' or \'FILE\'\n"
. "$usageMsg")
unless ($fasta =~ m/(\S+\,)+/ || $fasta =~ m/(\S+)/);

###################
# Store information from Fasta files.
my @fastaFileList;

if ($fasta =~ m/\,/) {
	@fastaFileList = split /\,/, $fasta;
} else {
	my $fastaFile = $fasta;
	push @fastaFileList, $fastaFile;
}

####################
# Save chromosome sequences with coordiantes.

# Save the chromosome sequences and cooridinates in this hash table.
my %chrSeq; 

{
	# Remember the last Fasta header.
	my $lastHeader = "";

	foreach my $fastaFile (@fastaFileList) {
		open my $fh, "<", $fastaFile or die "Error $fastaFile: $!\n";
		while (<$fh>) {
			chomp;
			if (/\A>/) {
				if ($lastHeader) {
					# If the last sequence of this fasta entry was reached remove the additional coordinate.
					$chrSeq{$lastHeader}->stopCoor;
				}
				$chrSeq{$_}= ChrSeqCor->new($_);
				$lastHeader = $_;
			} elsif (/\A\S/) {
				# Save the sequence and coordinates in ChrSeqCor object.
				my $seqLen = length $_;
				$chrSeq{$lastHeader}->setCoor($seqLen,$_);
			}
		}
		# If the last sequence of this fasta entry was reached remove the additional coordinate.
		$chrSeq{$lastHeader}->stopCoor;
		$lastHeader = "";
		close $fh;
	}
}

####################
# Test code for the fasta sequence assessment:
#foreach (sort keys %chrSeq) {
#	print "header:\n$_\n\n";
#	my $newCoorRef = \$chrSeq{$_}->getCoor;
#	foreach my $coor (sort keys %{ $$newCoorRef }) {
#		print "coordinate: ", $coor, "\n";
#		print "sequence: ", $$newCoorRef->{$coor}, "\n\n";
#	}
#	print "\n";
#}
#my @ele = sort keys %chrSeq;
#my $res = $chrSeq{$ele[0]}->getSpecCoor(5,10);
#print "seq at coordinate 5 to 10:\n$res\n";
#$res = $chrSeq{$ele[0]}->getSpecCoor(4,10);
#print "\nseq at coordinate 4 to 10:\n$res\n";


####################
# Save gff3 coordinates.
# Here are the fields: EnsemblGeneID	ChromsomeNumber	StartPos	StopPos
my %gff3Coor;

open my $fh, "<", $targetList;

while (<$fh>) {
	chomp;
	unless (/\A#/) {
		my @line = split /\t/;
		$gff3Coor{$line[0]} = [ ($line[1], $line[0], $line[2], $line[3]) ];
	}
}

close $fh;



####################
# Query the gff3 file.

open $fh, "<", $gff3 or die "Error $gff3: $!\n";

{
	my $readStatus = "";
	my $lastGene = "";
	while (<$fh>) {
		chomp;
		unless (/\A##/ || /\A#!/) {
			my @line = split /\t/;
			my @annotation = split /;/, $line[8];
			$annotation[0] =~ s/\AID=gene://;
			foreach my $gene (sort keys %gff3Coor) {
				if ($line[0] eq $gff3Coor{$gene}->[0]
						&& $line[2] eq "gene" 
						&& $line[3] == $gff3Coor{$gene}->[2]
						&& $line[4] == $gff3Coor{$gene}->[3]
						&& $annotation[0] eq $gene
				   ) {
					# Start reading gene information.
					$readStatus = "start";
					$lastGene = $gene;
				}
				
			}

		}
		if ($readStatus && $lastGene && !(/\A#/)) {
			# Read each line and remember interesting annotations.
			my @line = split /\t/;
			if ($line[2] eq "exon") { # maybe ill add this another time || $line[2] eq "five_prime_UTR" ||$line[2] eq "three_prime_UTR") {
				if ($gff3Coor{$lastGene}->[4]) {
					push @{ $gff3Coor{$lastGene}->[4] }, [ ($line[2], $line[3], $line[4] ) ];
				} else {
					$gff3Coor{$lastGene}->[4] = [ [ ($line[2], $line[3], $line[4] ) ] ];
				}
			}
		}
		if (/\A###/) {
			# End of gene sequence.
			$readStatus = "";
			$lastGene = "";
		}
	}
	close $fh;
}

####################
# Add introns upstream and downstream regions to the genes of interest.

foreach my $gene (sort keys %gff3Coor) {
	my $lastExon = "";
	foreach my $category (@{ $gff3Coor{$gene}->[4] }) {
		if ($category->[0] eq "exon" && $lastExon) {
			# Append an intron at the end of the array if it is a sequence between 2 exons.
			push @{ $gff3Coor{$gene}->[4] }, [ ("intron", $lastExon + 1, $category->[2] - 1 ) ];
		}
		if ($category->[0] eq "exon") {
			$lastExon = $category->[2];
		}
	}
	$lastExon = "";
	if ($upstream > 0) {
			die "Error value \"$upstream\" in option --upstream is smaller than first nucleotide of chromosome $gff3Coor{$gene}->[0]"
				if ($gff3Coor{$gene}->[2] - $upstream < 0);

			push @{ $gff3Coor{$gene}->[4] }, [ ("upstream", $gff3Coor{$gene}->[2] - $upstream, $gff3Coor{$gene}->[2] - 1) ];
	}
	if ($downstream > 0) {
			push @{ $gff3Coor{$gene}->[4] }, [ ("downstream", $gff3Coor{$gene}->[3] + 1, $gff3Coor{$gene}->[3] + $downstream) ];
	}
}

####################
# Extract all interesting genes and categories form the fasta files.

foreach my $header (sort keys %chrSeq) {
	my @headInfo = map {
				my @tmp;
				if ($_ =~ /\Achromosome/) {
					@tmp = split /:/, $_;
					@tmp;
				} else {
					();
				}
				} split / /, $header;
	foreach my $gene (sort keys %gff3Coor) {
		if ($gff3Coor{$gene}->[0] == $headInfo[2]) {
			foreach my $category (@{ $gff3Coor{$gene}->[4] }) {
				print ">$gene|category:$category->[0]|chromosome:$headInfo[2]|$category->[1]|$category->[2]\n";
				foreach my $resLine ($chrSeq{$header}->getSpecCoor($category->[1],$category->[2])) {
					print "$resLine\n";
				}
			}
		} 
	}
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

########################################
# Classes/Packages:

####################
# ChrSeqCor Class. Instantiated objects remember sequences, cooordinates and header information.
{ package ChrSeqCor;
	##########
	# Constructor:
	sub new {
		my $class = shift;
		my $header = shift;

		# Test whether all arguments have been provided.
		my %providedArgs = (class => \$class, header => \$header);
		foreach (sort keys %providedArgs) {
			die "Error in package ChrSeqCor: "
			. "Argument $_ was not provided.\n" unless (${ $providedArgs{$_} });
		}

		my $self = { HEADER => $header, COOR => { 0 => "" }, NEXTCOOR => 0 };

		bless $self, $class;
	}

	##########
	# Setters:
	sub setCoor {
		my $self = shift;
		my $currLen = shift;
		my $newSeq = shift;
		if ($self->{NEXTCOOR}) {
			my $coordinate = $self->{NEXTCOOR};
			$self->{COOR}->{$coordinate} = $newSeq;

			my $newCoor = $coordinate + $currLen;
			$self->{COOR}->{$newCoor} = "";
			$self->{NEXTCOOR} = $newCoor;
		} else {
			$self->{COOR}->{0} = $newSeq;
			$self->{COOR}->{$currLen} = "";
			$self->{NEXTCOOR} = $currLen;
		}
		return undef;
	}

	sub stopCoor {
		my $self = shift;
		delete $self->{COOR}->{$self->{NEXTCOOR}};
	}

	##########
	# Getters:
	sub getHeader {
		my $self = shift;
		return $self->{HEADER};
	}

	sub getAllSeqs {
		my $self = shift;
		return $self->{COOR};
	}

	# Retrieve a specific sequence from a coordinate query.
	sub getSpecCoor {
		my $self = shift;
		my $queryCoor = shift;
		my $endCoor = shift;
		my $lastRange = 0;
		my $length = $endCoor - $queryCoor;
		my @res;
		if ($self->{COOR}->{$queryCoor}) {
			push @res, $self->{COOR}->{$queryCoor};
		}

		foreach my $range (sort {$a <=> $b} keys ($self->{COOR})) {
			if ($queryCoor > $lastRange && $queryCoor < $range && !(@res)) {
				my $pos = $queryCoor - $lastRange;
				push @res, (substr $self->{COOR}->{$lastRange}, $pos);
			}
			if ($endCoor > $lastRange && $endCoor < $range) {
				pop @res;
				# Determine the substring end position of this array slice.
				my $pos = $endCoor - $lastRange;
				push @res, (substr $self->{COOR}->{$lastRange}, 0, $pos);
				last;
			}
			if ($self->{COOR}->{$endCoor}) {
				push @res, $self->{COOR}->{$endCoor};
				last;
			}
			if (@res) {
				push @res, $self->{COOR}->{$range};
			}
			$lastRange = $range;
		}
		return @res;
	}
}