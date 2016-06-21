#! /usr/bin/perl -w 

use strict;
use 5.010;
use utf8;

die "USAGE: ./create_slurm_scripts.pl <job prefix>" unless (@ARGV == 1); #Here can be the job prefix "10k_1kbp_sim_"

my $prefix = shift @ARGV;

my $first = 1;
my $last = 10;
my $counter;
for ($counter = 1; $counter < 1001; $counter ++) {
	if ($first > 10000) {
		last;
	}
	$last = 10 * $counter;
	my $file = $prefix . "_job_" . $counter . ".sh";
	open my $fh, ">", $file or die "$file: $!\n";
	print $fh '#!/bin/bash -l
#SBATCH --cpus-per-task=1
#SBATCH --mem=8096mb
#SBATCH --time=96:00:00
#SBATCH --account=UniKoeln
# number of nodes in $SLURM_NNODES (default: 1)
# number of tasks in $SLURM_NTASKS (default: 1)
# number of tasks per node in $SLURM_NTASKS_PER_NODE (default: 1)
# number of threads per task in $SLURM_CPUS_PER_TASK (default: 1)
JAVABIN="/home/krausc0/programmes/jdk1.8.0_66/bin/java -jar -Xmx8G"
';
	for (my $i = $first; $i < ($last + 1); $i ++) {
		print $fh '$JAVABIN /home/krausc0/programmes/Strings/target/release/modulebatchrunner.jar -c ';
		my $command = './' . $prefix . $i . '.exp' . ' >' . $prefix . $i . '.exp.log 2>' . $prefix . $i . '.exp.err.log' . "\n";
		print $fh "$command";
	}
	$first = $last + 1;
	close $fh;
}
