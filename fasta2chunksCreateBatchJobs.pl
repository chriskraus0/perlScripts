#! /usr/bin/perl -w 

################################################################################
# The aim of this script is to create an apropriate number of preconfigured SLURM scripts
# for usage on CHEOPS. It reads fasta and splits them to a pre-defined number of smaller
# fasta files.
################################################################################

use strict;
use 5.010;
use utf8;
use Getopt::Long;
use Cwd;	# Module to provide information about the current directory.

####################
# Get working directory and move to that directory.
my $dir = getcwd;
chdir $dir;

####################
# USAGE message:
my $usageMsg = "\nUSAGE: $0 "
	. "--chunks=<NUM> --fastaFile=<FILE>"
	. "--outpat=<OutPatternName> --cpu=<NUM> --time=<NUM> --mem=<NUM>\n"
	. "--ncbiDir=\'<NCBI NR Directory>\'\n\n"
	. "HELP: For help type $0 --help\n\n";


####################
# HELP message:
my $helpMsg = "NAME\n\n" 
		. "\t $0 - The aim of this script is to create an apropriate number\n"
		. "of preconfigured\n"
		. "\t batchrunner experiments and SLURM scripts for usage on CHEOPS.\n\n"

		. "$usageMsg"

		. "ATTENTION\n"
		. "\tAll 11 command line options are required.\n\n"

		. "OPTIONS\n"

		. "\t --chunks=<NUM>\tThe number of resulting fasta files and\n"
		. "\t\t\t SLURM scripts which will be generated\n\n"

		. "\t --fastaFile=<FILE>\tThe path and name of the fasta file to be split.\n\n"

		. "\t --outpat=<OutPatternName>\tThe naming pattern for the output files.\n"
		. "\t\t\tEXAMPLE: \"--chunks=3 --outpat=fooBar\" will generate the files:\n"
		. "\t\t\t\t\tfooBar_0.fasta\n"
		. "\t\t\t\t\tfooBar_0_SLURM.sh\n"
		. "\t\t\t\t\tfooBar_1.fasta\n"
		. "\t\t\t\t\tfooBar_2_SLURM.sh\n"
		. "\t\t\t\t\tfooBar_2.fasta\n"
		. "\t\t\t\t\tfooBar_2_SLURM.sh\n\n"

		. "\t --cpu=<NUM>\tspecified number of CPUs for SMP job.\n"
		. "\t\t\tRange: 2 - 128\n\n"

		. "\t --time=<NUM>\tspecified wall-time for a SMP job in hours.\n"
		. "\t\t\t Range: 1 - 720\n\n"

		. "\t --mem=<NUM>\tspecified size of RAM for an SMP job in gigabytes (Gb).\n"
		. "\t\t\t Range: 4 - 504\n\n"

		. "\t --ncbiDir=\'<NCBI NR Directory>\'\tThe Path leading to the\n"
		. "\t\t\tNCBI NR directory\n\n";
		
####################
#Catch argument errors.
if (@ARGV == 1 && $ARGV[0] eq "--help") {
	print "$helpMsg";
	exit 0;
}

warn ("\nWarning: All Arguments are required.\n\n") unless (@ARGV == 7);

####################
#Read all parameters from command line options.
my $chunks;
my $fastaFile; 
my $outPattern;
my $cpu;
my $time;
my $mem;
my $ncbiDir;

GetOptions ("chunks=i" => \$chunks,
	"fastaFile=s" => \$fastaFile,
	"outpat=s" => \$outPattern,
	"cpu=i" => \$cpu,
	"time=i" => \$time,
	"mem=i" => \$mem,
	"ncbiDir=s" => \$ncbiDir)
or die("Error in command line arguments.\n" . "$usageMsg");

####################
#Catch argument errors.
&argumentError("chunks", $usageMsg) unless ($chunks);
&argumentError("fastaFile", $usageMsg) unless ($fastaFile);
&argumentError("outpat", $usageMsg) unless ($outPattern);
&argumentError("cpu", $usageMsg) unless ($cpu);
&argumentError("time", $usageMsg) unless ($time);
&argumentError("mem", $usageMsg) unless ($mem);
&argumentError("ncbiDir", $usageMsg) unless ($ncbiDir);

####################
# Catch non-number errors.
if (&isNotNumber($chunks)) {
	die ("Error in --chunks option: \"$chunks\" is not a number" . "$usageMsg")
}
if (&isNotNumber($cpu)) {
	die ("Error in --cpu option: \"$cpu\" is not a number" . "$usageMsg")
}
if (&isNotNumber($mem)) {
	die ("Error in --cpu option: \"$mem\" is not a number" . "$usageMsg")
}
if (&isNotNumber($time)) {
	die ("Error in --cpu option: \"$time\" is not a number" . "$usageMsg")
}

####################
# Catch non-ascii error.

if ($outPattern =~ /([^[:ascii:]])/) {
	my $asErr = $1;
	die "Error: Non-Ascii sign \"$asErr\" found in --outpat option:\n"
	. "$outPattern\n" . "$usageMsg";
}

####################
# Prepare output pattern.

my @outP;
for (my $i = 0; $i < $chunks; $i ++) {
	$outP[$i] = $outPattern . "_" . "$i";
}

####################
# Read fasta file.

# Save sequences in hash.
my %seqs;

open my $fh, "<", $fastaFile or die "Error: $fastaFile: $!\n";

my $currentHeader = "";
while (<$fh>) {
	chomp;
	if (/\A>/) {
		$currentHeader = $_;
	} elsif (/\A\w/) {
		if ($currentHeader) {
			if ($seqs{$currentHeader}) {
				push @{ $seqs{$currentHeader } }, $_;
			} else {
				$seqs{$currentHeader} = [ $_ ];
			}
		}
	}
}

close $fh;

####################
# Split fasta into specific amount of chunks.

my @seqNames = keys %seqs;
my $numSeqs = @seqNames;

my $newNumSeqs = $numSeqs;

my $chunkFlag = "";

while ($newNumSeqs % $chunks) {
	$newNumSeqs --;
}

my $remainSeqs = $numSeqs - $newNumSeqs;

my $chunkSize = $newNumSeqs / $chunks;

# Increment $chunks if modulo operation is true.
if ($numSeqs % $chunks) {
	$chunks ++;
	my $newPat = $outPattern . "_" . ($chunks - 1); 
	push @outP, $newPat;
	$chunkFlag = "true";
}

# Write new fasta files.

for (my $i = 0; $i < $chunks; $i ++) {
	my $fileName = $outP[$i] . ".fasta";
	open my $ofh, ">", $fileName or die "Error: $fileName: $!\n";
	if ($i == $chunks - 1 && $chunkFlag) {
		for (my $j = 0; $j < $remainSeqs; $j ++) {
			print $ofh "$seqNames[$i * $chunkSize + $j]\n";
			foreach my $line (@{ $seqs{$seqNames[$i * $chunkSize + $j]} }) {
				print $ofh "$line" . "\n";
			}
		}
	} else {
		for (my $j = 0; $j < $chunkSize; $j ++) {
			print $ofh "$seqNames[$i * $chunkSize + $j]\n";
			foreach my $line (@{ $seqs{$seqNames[$i * $chunkSize + $j]} }) {
				print $ofh "$line" . "\n";
			}
		}
	}
	close $ofh;
}

####################
# Prepare SLURM scripts.

for (my $i = 0; $i < $chunks; $i ++) {
	my $slurmOut = $outP[$i] . "_Slurm.sh";

	open my $ofh, ">", $slurmOut or die "Error $slurmOut: $!\n";

	#Write the SLURM scripts
	print $ofh "#!/bin/bash -l\n";
	print $ofh "#SBATCH --cpus-per-task=$cpu\n";
	print $ofh "#SBATCH --mem=${mem}gb\n";
	print $ofh "#SBATCH --time=${time}:00:00\n";
	print $ofh "#SBATCH --account=UniKoeln\n";
	print $ofh '# number of nodes in $SLURM_NNODES (default: 1)' . "\n";
	print $ofh '# number of tasks in $SLURM_NTASKS (default: 1)' . "\n";
	print $ofh '# number of tasks per node in $SLURM_NTASKS_PER_NODE (default: 1)' . "\n";
	print $ofh '# number of threads per task in $SLURM_CPUS_PER_TASK (default: 1)' . "\n";
	print $ofh "sleep 2m\n";
	print $ofh "module load blast+/2.2.29\n\n";
	print $ofh 'blastp -num_threads ' . "$cpu" . ' -max_target_seqs 200 -evalue 1e-5 -query ' . $outP[$i] . ".fasta " . '-db ' . "$ncbiDir" . ' -out ' . $outP[$i] . ".blast.out" . ' -outfmt 14';
	print $ofh " 1>$outP[$i].blast.out.log 2>$outP[$i].blast.err\n";

	close $ofh;
}

########################################
# Functions:

####################
# Test whether an array contains a specific element.
sub containsEl {
	my $myArray = shift @_;
	my $myElement = shift @_;
	my $myReturn = 0;
	foreach (@{ $myArray }) {
		if ($_ eq $myElement) {
			$myReturn = $myElement;
		}
	}
	return $myReturn;
}

####################
# Test whether the argument is a number.
sub isNotNumber {
	my $myVal = shift @_;
	if ($myVal =~ /[0-9]+/) {
		# Is a number return false.
		return 0;
	} else {
		# Is a number return true.
		return 0;
	}
}

####################
# Print out error message for missing command line argument.
sub argumentError {
	my $missingArg = shift @_;
	my $usageMsg = shift @_;
    	die "Error \"--$missingArg\": Argument not initialised.\n" . $usageMsg;
}
