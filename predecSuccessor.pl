#! /usr/bin/perl

################################################################################
# This script goes through a csv file and extracts predecessors or successors
# for a certain kind of string.
################################################################################


use utf8;
use 5.012;
use strict;
use warnings;
use Getopt::Long; #command line option module
use Cwd;	#module to provide information about current directory

####################
# Get working directory and move to that directory.
my $dir = getcwd;
chdir $dir;

####################
# USAGE message:
my $usageMsg = "USAGE: ./predecSuccessor.pl --suc=<F|T> --csv=<FILE> --string=<STRING>\n\n"
		. "For help type $0 --help\n";


####################
# HELP message:
my $helpMsg = "NAME\n\n" 
		. "$0\n"
		. "\n$usageMsg\n"
		. "\n\nOptions:\n\n"
		. "\t--suc=<T|F>\tadd \"T\" for successor (true) OR \"F\" for predecessor (false)\n\n"
		. "\t--csv=<FILE>\tinsert csv file or matrix from which will be read\n\n"
		. "\t--string=<STRING>\tinsert single (continuous) string of interest\n\n"
		. "\t--stringEnd=<[a-zA-Z0-9]\$*|!>\t stringEnd contains the \"End of String\" character.\n"
		. "\t\t\toften \"\$\" is used. \"!\" defines no \"End of String\" character.\n\n";

####################
# Catch argument errors.
if (@ARGV == 1 && $ARGV[0] eq "--help") {
	print "$helpMsg";
	exit 0;
}

warn ("\nWarning: All Arguments are required.\n\n") unless (@ARGV == 4);

####################
# Read all parameters from command line options.

my $successor;
my $csvFile;
my $myString;
my $stringEnd;

GetOptions ("suc=s" => \$successor,
	"csv=s" => \$csvFile,
	"string=s" => \$myString,
	"stringEnd=s" => \$stringEnd)
or die("Error in command line arguments.\n" . "$usageMsg");

my %parsedArgs = ("suc=s" => \$successor, "csv=s" => \$csvFile, "string=s" => \$myString, "stringEnd=s" => \$stringEnd);

####################
# Catch argument errors.
my $missedArg = 0;
foreach my $arg (sort keys %parsedArgs) {
	$missedArg = &argumentError($arg) unless (${$parsedArgs{$arg}} eq "0" || ${$parsedArgs{$arg}});
}

die "Error: Necessary arguments not provided.\n\n$usageMsg\n" if ($missedArg);

####################
# Catch argument content errors.
die "Error: Option \"--suc\" contains not allowed signs: \"$successor\".\n"
	. "Only \"T\" (true) or \"F\" (false) allowed\n" unless ($successor eq "T" || $successor eq "F");

die "Error: Option \"--stringEnd\" must contain a single ASCII character or \'!\' for nothing\n. \"$stringEnd\" is not allowed.\n"
	unless ($stringEnd =~ /\S/ || $stringEnd =~ /!/);

if ($stringEnd eq "!") {
	$stringEnd = "";
} elsif ($stringEnd eq '$' || $stringEnd eq '*') {
	$stringEnd =~ s/^/\\/;
}

####################
# Read csv file.

my %query;
my @result;
my @queryArray;

open my $fh, "<", $csvFile or die "Error: $csvFile: $!\n";

{
	my $col = 0;
	while (<$fh>) {
		chomp; 
		
		# Read rows as current strings and columns as successors.
		if ((/\A\w+;[0-1;]/ || /\A$stringEnd;[0-1;]/) && $successor eq "T") {
			my @line = split /;/;
			my $currString = shift @line;
			@line = map {$_ eq "" ? "0" : $_} @line;
			$query{$currString} = [ ( @line ) ];
		} elsif ((/[a-zA-z]+$stringEnd;[a-zA-z]+$stringEnd/) && $successor eq "T") {
			@result = split /;/;
			# First column seems to be empty anyway and will be discarded.
			shift @result;
		}
		
		# Read columns as current strings and rows as predecessors.
		elsif ((/[a-zA-z]+$stringEnd;[a-zA-z]+$stringEnd/) && $successor eq "F") {
			my @line = split /;/;
			# First column seems to be empty anyway and will be discarded.
			shift @line;
			my $pos = 0;
			foreach (@line) {
				$query{$_} = $pos;
				$pos ++;
				push @queryArray, $_;
			}
		} elsif ((/\A\w+;[0-1;]/ || /\A$stringEnd;[0-1;]/) && $successor eq "F") {
			my @line = split /;/;
			shift @line;
			@line = map {$_ eq "" ? "0" : $_} @line;
			push @result, [ ($col, @line) ];
			$col ++;
		}
	}
}

close $fh;

####################
# Find successors or predecessors.

if ($successor eq "T") {
	if ($query{$myString}) {
		my $pos = 0;
		foreach my $entry (@{ $query{$myString} }) {
			if ($entry == "1") {
				print "$result[$pos];";
			}
			$pos ++;
		}
		print "\n";
	} else {
		die "Error: The query \"$myString\" is not part of this table: $csvFile\n";
	}
} elsif ($successor eq "F") {
	my $hit = 0;
	if ($query{$myString}) {
		# @results an @array of an @array which includes the column number in the first element thus "+1".
		my $queryPos = $query{$myString} + 1;
		foreach my $entry (@result) {
			if ($entry->[$queryPos] == "1") {
				print "$queryArray[$entry->[0]];";
				$hit ++;
			}
		}
		print "no predecessor found for string \"$myString\"" if ($hit == 0);
		print "\n";
	} else {
		die "Error: The query \"$myString\" is not part of this table: $csvFile\n";
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


