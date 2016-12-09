#! /usr/bin/perl


################################################################################
# This perl script goes through sam files and extracts locus IDs. 
# Afterwards it goes through a tags file and extracts the read ids per stack and RadTag.
# ################################################################################

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
# USAGE message:
my $usageMsg = "USAGE: ./getReadsFromTags.pl --samFile=<FILE> --tagsFile=<FILE>\n";

####################
# Catch argument errors.
warn ("\nWarning: All Arguments are required.\n\n") unless (@ARGV == 2);

####################
# Read all parameters from command line options.

my $samFile;
my $tagsFile;

GetOptions ("samFile=s" => \$samFile,
		"tagsFile=s" => \$tagsFile)
or die("Error in command line arguments.\n" . "$usageMsg");

my %parsedArgs = (samFile => \$samFile, tagsFile => \$tagsFile);

####################
# Catch argument errors.
my $missedArg = 0;
foreach my $arg (sort keys %parsedArgs) {
	$missedArg = &argumentError($arg) unless (${$parsedArgs{$arg}} eq "0" || ${$parsedArgs{$arg}});
}

die "Error: Necessary arguments not provided.\n\n$usageMsg\n" if ($missedArg);

####################
# Read tag names from sam file.
open my $fh, "<", $samFile; 

my %res; 

while (<$fh>) {
	unless (/\A\@/) {
		chomp; 
		(my $id, my @dummy) = split /\t/;  
		$id =~ s/\A\S+\|LOCID_//;
		$res{$id}=""; 
	}
} 
close $fh; 

####################
# Open tags file and extract all read IDs.

open $fh, "<", $tagsFile;

while (<$fh>) {
	chomp; 
	(my $dummy, my $dummy1, my $locID, my $dummy3, my $dummy4,
		my $dummy5, my $dummy6, my $dummy7, my $id, my @dummy) = split /\t/;  
	if ($id =~ /\A[A-Z][0-9][0-9][0-9][0-9][0-9]:/) {
		if ($res{$locID}) {
			push @{ $res{$locID} }, $id;
		} else {
			$res{$locID}= [ ($id) ]; 
		}
	}
} 
close $fh; 

####################
# Write results.

foreach my $locID ( sort keys %res) {
	foreach my $id (@{ $res{$locID} }) {
	print "$id\n";
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


