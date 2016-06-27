#! /usr/bin/perl -w 

################################################################################
#The aim of this script is to create an apropriate number of preconfigured SLURM scripts
#for usage on CHEOPS.
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
my $usageMsg = "\nUSAGE: ./create_slurm_scripts.pl "
	. "--iter=<NUM> --template=<EXPERIMENT.exp> --line=\"<NUM,NUM,NUM,...>\""
	. "--regex=\'</REGEX/,/REGEX/,...>\' --outpat=<OutPatternName> --cpu=<NUM> --time=<NUM> --mem=<NUM>\n"
	. "--javaDir=\'<JavaExcutableDirectory>\' --batchRunnerDir=\'<ModulebatchRunnerDirectory>\'\n\n"
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

		. "\t --iter=<NUM>\tThe number of iterations or experiments and\n"
		. "\t\t\t SLURM scripts which will be generated\n\n"

		. "\t --template=<EXPERIMENT.exp>\tA template experiment in JSON\n"
		. "\t\t\t format. ATTENTION fortmat check not included yet!\n\n"

		. "\t --line=\"<NUM,NUM,NUM,...>\"\tA specified number(s) of the\n"
		. "\t\t\t line(s) which should be changed in the template experiment\n"
		. "\t\t\tEXAMPLE: --line=\"102,205,302,304\"\n\n"

		. "\t --regex=\'</REGEX/,/REGEX/,...>\'\t A regex command which"
		. "\t\t\t specifies the number of required\n" 
		. "\t\tfor e.g. an output or input file\n"
		. "\t\t\tEXAMPLE: --regex\'/_2_/,/A[0-9]*\$/\'"
		. "\t\t\tATTENTION: The number of regular expressions (regex) and\n"
		. "\t\t\t the number of interchangable lines must\n"
		. "\t\t\t\tbe the same!\n"
		. "\t\t\tATTENTION: --regex must include at least one number which\n"
		. "\t\t\t should be exchanged.\n\n"

		. "\t --outpat=<OutPatternName>\tThe naming pattern for the output files.\n"
		. "\t\t\tEXAMPLE: \"--iter=3 --outpat=fooBar\" will generate the files:\n"
		. "\t\t\t\t\tfooBar_0.exp\n"
		. "\t\t\t\t\tfooBar_0_SLURM.sh\n"
		. "\t\t\t\t\tfooBar_1.exp\n"
		. "\t\t\t\t\tfooBar_2_SLURM.sh\n"
		. "\t\t\t\t\tfooBar_2.exp\n"
		. "\t\t\t\t\tfooBar_2_SLURM.sh\n\n"

		. "\t --cpu=<NUM>\tspecified number of CPUs for SMP job.\n"
		. "\t\t\tRange: 2 - 128\n\n"

		. "\t --time=<NUM>\tspecified wall-time for a SMP job in hours.\n"
		. "\t\t\t Range: 1 - 720\n\n"

		. "\t --mem=<NUM>\tspecified size of RAM for an SMP job in gigabytes (Gb).\n"
		. "\t\t\t Range: 4 - 504\n\n"

		. "\t --javaDir=\'<JavaExcutableDirectory>\'\tThe Path leading to the\n"
		. "\t\t\tjava (v8SE) bin file\n"
		. "\t\t\tATTENTION: java binary not included, just the path!\n\n"

		. "\t --batchRunnerDir=\'<ModulebatchRunnerDirectory>\'\tThe Path leading to the\n"
		. "\t\t\tmodulebatchrunner.jar file\n"
		. "\t\t\tATTENTION: modulebatchrunner.jar not included, just the path!\n\n";
		
####################
#Catch argument errors.
if (@ARGV == 1 && $ARGV[0] eq "--help") {
	print "$helpMsg";
	exit 0;
}

warn ("\nWarning: All Arguments are required.\n\n") unless (@ARGV == 10);

####################
#Read all parameters from command line options.
my $iter;
my $template;
my $line;
my $regexCh;
my $outPattern;
my $cpu;
my $time;
my $mem;
my $javaDir;
my $batchRunnerDir;

GetOptions ("iter=i" => \$iter,
	"template=s" => \$template,
	"line=s"   => \$line,
	"regex=s" => \$regexCh,
	"outpat=s" => \$outPattern,
	"cpu=i" => \$cpu,
	"time=i" => \$time,
	"mem=i" => \$mem,
	"javaDir=s" => \$javaDir,
	"batchRunnerDir=s" => \$batchRunnerDir)
or die("Error in command line arguments.\n" . "$usageMsg");

####################
#Catch argument errors.
&argumentError("iter", $usageMsg) unless ($iter);
&argumentError("template", $usageMsg) unless ($template);
&argumentError("line", $usageMsg) unless ($line);
&argumentError("regex", $usageMsg) unless ($regexCh);
&argumentError("outpat", $usageMsg) unless ($outPattern);
&argumentError("cpu", $usageMsg) unless ($cpu);
&argumentError("time", $usageMsg) unless ($time);
&argumentError("mem", $usageMsg) unless ($mem);
&argumentError("javaDir", $usageMsg) unless ($javaDir);
&argumentError("batchRunnerDir", $usageMsg) unless ($batchRunnerDir);

####################
# Catch non-number errors.
if (&isNotNumber($iter)) {
	die ("Error in --iter option: \"$iter\" is not a number" . "$usageMsg")
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
# Store the number of lines to be exchanged.
my @line;

if ($line =~ m/\,/) {
	@line = split /\,/, $line;
} else {
	@line = $line;
}


####################
# Catch error in regex pattern.
die ("Error in --regex option.\n"
. "--regex must be the pattern \'/REGEX/,...\' or \'/REGEX/\'\n"
. "$usageMsg")
unless ($regexCh =~ m/(\/\S+\/\,)+/ || $regexCh =~ m/(\/\S+\/)/);

####################
# Store the different regex to be exchanged.
my @reg;

if ($regexCh =~ m/\,/) {
	@reg = split /\,/, $regexCh;
	foreach my $reg (@reg) {
		shift @reg;
		$reg =~ s/\A\///;
		$reg =~ s/\/\Z//;
		push @reg, $reg;
	}
} else {
	my $reg = $regexCh;
	$reg =~ s/\A\///;
	$reg =~ s/\/\Z//;
	push @reg, $reg;
}

####################
# Catch amount of lines vs amount of regex error.
my $lineNum = @line;
my $regexNum = keys @reg;

die ("Error amount of arguments in --regex option and --line option are not equal: Only one exchange per line allowed.\n"
	. "--line: $lineNum --regex: $regexNum\n" . "$usageMsg")
unless ($lineNum == $regexNum);

####################
# Save the different regex in a regex hash table.

my %regexHash;

my $counter = 0;
foreach my $currLine (@line) {
	$regexHash{$currLine} = $reg[$counter];
	$counter ++;
}

####################
# Read the template and remember the non-exchangable lines.
open my $fh, "<", $template or die "\nError $template: $!\n";

my %templateLines;

# Remember amount of total lines in template.
my $totalLines;

# Remember the specific lines to be exchanged.
my %exchLines;

#Forget $currLineNum soon after closing this code block.
{
	# Remember the current line of the template.
	my $currLineNum = 1;
	my $nextIt = 0;

	while (<$fh>) {
		chomp;
		foreach my $exLine (@line) {
			if ($exLine == $currLineNum) {
				# Remember the specific lines to be exchanged.
				$exchLines{$exLine} = $_;
				$nextIt = 1;
				next;
			}
		}
		unless ($nextIt) {
			$templateLines{$currLineNum} = $_;
			$currLineNum ++;
		} else {
			$currLineNum ++;
			$nextIt = 0;
			next;
		}
	}
	# Remember the specific lines to be exchanged. 
	# ATTENTION: additional "-1" due to post-fence error!
	$totalLines = $currLineNum - 1;
}

close $fh;

####################
# Catch REGEX not detected error.
foreach my $currLine (@line) {
	unless ($exchLines{$currLine} =~ m/$regexHash{$currLine}/) {
		die "Error argument --regex $regexHash{$currLine} not found in line number $currLine:\n"
			. "\"$exchLines{$currLine}\"\n" . "$usageMsg";
	}
}

####################
# Prepare exchanged lines.
my %intermediateLines;

for my $currLine (@line) {
	unless ($regexHash{$currLine} =~ m/[0-9]/) {
		# Catch no number found error.
		die "Error no number found in $regexHash{$currLine}.\n" . "$usageMsg";
	} else {
		for (my $i = 0; $i < $iter; $i ++) {
			# Exchange patterns.
			my $newLine = $exchLines{$currLine};
			my $newPattern = $regexHash{$currLine};
			$newPattern =~ s/[0-9]/$i/;
			unless ($newLine =~ /$newPattern/) {
				$newLine =~ s/$regexHash{$currLine}/$newPattern/;
			}
			if (%intermediateLines) {
				push @{ $intermediateLines{$currLine} }, ($newLine);
			} else {
				$intermediateLines{$currLine}= [ ($newLine) ]
			}
		}
	}
}

# Exchange exchanged lines for new arrays.
foreach my $currLine (sort keys %exchLines) {
	$exchLines{$currLine} = $intermediateLines{$currLine};
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
for (my $i = 0; $i < $iter; $i ++) {
	$outP[$i] = $outPattern . "_" . "$i";
}

####################
# Create new template scripts.

#Array ref on @line for usage in fuctions.
my $lineRef = \@line;

for (my $i = 0; $i < $iter; $i ++) {

	# Create a file for each script.
	my $expOut = $outP[$i] . ".exp";
	open my $efh, ">", $expOut or die "Error $expOut: $!\n";

	for (my $currLineNum = 1; $currLineNum < ($totalLines + 1); $currLineNum ++) {
		if (&containsEl($lineRef, $currLineNum)) {
			print $efh "$exchLines{$currLineNum}->[$i]\n";
		} else {
			print $efh "$templateLines{$currLineNum}\n";
		}
	}
	close $efh;
}

####################
# Catch not enough memory error.
die "Error in \"--mem\": Not enough memory.\n"
	."Please use at least 4 Gb of RAM instead of $mem Gb.\n" . "$usageMsg" if ($mem < 4 );

####################
# Prepare SLURM scripts.

# Prepare heap space.
my $heapMem = sprintf "%.0f", ($mem * 0.8);

for (my $i = 0; $i < $iter; $i ++) {
	my $slurmOut = $outP[$i] . "_Slurm.sh";
	my $expOut = $outP[$i] . ".exp";

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
	print $ofh 'JAVABIN="' . "$javaDir/java" . ' -jar -Xmx' ."${heapMem}G" . "\"\n";
	print $ofh '$JAVABIN ' . "$batchRunnerDir" . '/modulebatchrunner.jar -c ';
	print $ofh "$expOut >$expOut.log 2>$expOut.err\n";

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
