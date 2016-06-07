#! /usr/bin/perl

################################################################################
# This perl script goes through any fasta file and extracts sequences specific
# for provided positions.
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
my $usageMsg = "USAGE: ./getFastaByCoor.pl --fastaFile=<FILE> --batchSeqs=<TSV TABLE FILE>\n"
		. "For help type $0 --help\n";


####################
#HELP message:
my $helpMsg = "NAME\n\n" 
		. "\t $0 - The aim of this script is to walk through fasta file\n"
		. "\t and extract sequences. Output will be in fasta format.\n\n"
		
		. "$usageMsg"

		. "ATTENTION\n"
		. "\tAll 2 command line options are required.\n\n"

		. "OPTIONS\n"

		. "\t--help\tprints this help message\n\n"

		. "\t --fastaFile=<FILE>\tInput of the provided fasta file\n"
		. "\t\t\t which should be searched.\n\n"

		. "\t --batchSeqs=<TSV TABLE FILE>\tProvided tsv table which\n"
		. "\t\t\t which includes information about the fasta file\n"
		. "\t\t\t and the start and stop position of the sequence of interest.\n"
		. "\t\t\t FIELDS:\n"
		. "\t\t\t SubjectFastaHeader\tQueryFastaHeader\tstartPos\tendPos\n"

		. "\n";


####################
#Catch argument errors.
if (@ARGV == 1 && $ARGV[0] eq "--help") {
	print "$helpMsg";
	exit 0;
}

warn ("\nWarning: All Arguments are required.\n\n") unless (@ARGV == 2);


####################
#Read all parameters from command line options.

my $fastaFile;
my $batchSeqs;

GetOptions ("fastaFile=s" => \$fastaFile,
	"batchSeqs=s" => \$batchSeqs)
or die("Error in command line arguments.\n" . "$usageMsg");

my %parsedArgs = (fastaFile => \$fastaFile, batchSeqs => \$batchSeqs);

####################
#Catch argument errors.
my $missedArg = 0;
foreach my $arg (sort keys %parsedArgs) {
	$missedArg = &argumentError($arg) unless (${$parsedArgs{$arg}} eq "0" || ${$parsedArgs{$arg}});
}

die "Error: Necessary arguments not provided.\n\n$usageMsg\n" if ($missedArg);


####################
# Save chromosome sequences with coordinates.

# Save the chromosome sequences and coordinates in this hash table.
my %chrSeq; 

{
	# Remember the last Fasta header.
	my $lastHeader = "";

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


####################
# Save search coordinates from provided tsv batchSeq file.

my %seqCoor;

{
	open my $fh, "<", $batchSeqs or die "Error $batchSeqs: $!\n";
	while (<$fh>) {
		chomp;
		unless ( /\A#/ )  {
			my @line = split /\t/;
			$seqCoor{$line[1]} = [ ($line[0], $line[2], $line[3]) ];
		}
	}
}

####################
# Extract all requested sequences.

foreach my $query (sort keys %seqCoor) {
	if ($chrSeq{$seqCoor{$query}->[0]}) {
		print $seqCoor{$query}->[0], "\|", $query, "\|", $seqCoor{$query}->[1], "\|", $seqCoor{$query}->[2], "\n";
		foreach my $line ($chrSeq{$seqCoor{$query}->[0]}->getSpecCoor($seqCoor{$query}->[1],$seqCoor{$query}->[2])) {
			print $line;
		}
		print "\n";
	} else {
		die "Error the fasta header \"" . $seqCoor{$query}->[0] . "\" was not found in file \"$fastaFile\"\n";
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
		#my $length = $endCoor - $queryCoor;
		my @res;
		if ($self->{COOR}->{$queryCoor}) {
			push @res, $self->{COOR}->{$queryCoor};
		}

		foreach my $range (sort {$a <=> $b} keys ($self->{COOR})) {

			# Deal with the query start.
			if ($queryCoor > $lastRange && $queryCoor < $range && !(@res)) {

				my $pos = $queryCoor - $lastRange;
				
				# If the endCoor is smaller than the current range then extract the array slice and stop.
				if ($endCoor < $range) {
					my $endPos = $range - $endCoor;

					#Change the distance to end of the array slice into distance to stop from the end.
					$endPos = $endPos * (-1);

					push @res, (substr $self->{COOR}->{$lastRange}, $pos, $endPos);
					last;

				} else {

					push @res, (substr $self->{COOR}->{$lastRange}, $pos);

				}

			} elsif (@res && $range > $queryCoor) {

				push @res, $self->{COOR}->{$range};

			}

			# Deal with the query end.
			if ($endCoor > $lastRange && $endCoor < $range) {

				pop @res;
				# Determine the substring end position of this array slice.
				my $pos = $endCoor - $lastRange;
				push @res, (substr $self->{COOR}->{$lastRange}, 0, $pos);
				last;

			} elsif ($range == $endCoor) {

				push @res, $self->{COOR}->{$endCoor};
				last;

			} 			

			$lastRange = $range;
		}
		return @res;
	}
}
