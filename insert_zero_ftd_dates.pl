#!/usr/bin/perl
use warnings;
use strict;

# insert_zero_ftd_dates.pl
#
# This file takes an input CSV data which contains FTD data
# and processes it against another file of trading dates
#
# if an FTD file skips one or more dates (when shares are traded)
# then a zero entry is inserted to the output file
# otherwise the output file contains the FTD dates
#
# not much error checking, 
#    - the command line is error checked
#    - existence of files, is checked
#
#    NO Checking for : 
#       - date file missing dates that are in FTD file ... (should never happen)
#
#    ADDED checking for :
#       - failure to align
#       - short date file (date file does not reach end date of FTD file) 
#
#


my $argc = 0;
foreach my $a(@ARGV) {
	$argc++;
}

#print "\n# args : " . $argc . "\n";

my $err_msg = "";

$err_msg  = "ERROR! : ";
$err_msg .= "insufficient # of args ... \n";
$err_msg .= "perl insert_zero_ftd_dates.pl <in_ftd_file> <in_date_file> <outfile> [skip_date_file]\n";
$err_msg .= "example command line :\nperl insert_zero_ftd_dates.pl mmat_ftds_2021.csv MMAT_prices.csv outfile.csv\n\n";

if ($argc < 3) { die $err_msg };

my $in_file_ftds  = $ARGV[0]; #$args[1];   # get filename 
my $in_file_dates = $ARGV[1]; #$args[2];   # get filename 
my $out_file_ftds = $ARGV[2]; #$args[3];   # get filename 
my $out_skip_dates = "";

if ($argc == 4) {
	$out_skip_dates = $ARGV[3]; #$args[3];   # get filename 
}

print "\n";
print "input ftd file  : " . $in_file_ftds . "\n"; 
print "input date file : " . $in_file_dates. "\n"; 
print "output file     : " . $out_file_ftds. "\n"; 

if ($argc == 4) {
	print "skip date file  : " . $out_skip_dates. "\n"; 
}

print "\n";


open(FH_FTDS,     '<', $in_file_ftds)  or die "ERROR - cannot open input ftd file : '$!'" ;
open(FH_DATES,    '<', $in_file_dates) or die "ERROR - cannot open input date file : '$!'";
open(FH_OUT_FTDS, '>', $out_file_ftds) or die "ERROR - cannot open output file : '$!'";

if ($argc == 4) {
	open(FH_SKIP_DATES, '>', $out_skip_dates) or die "ERROR - cannot open skip file : '$!'";
}


my $line = "";
my $last_line_ftd  = "";
my $last_line_date = "";

# dump header line from ftd file ...
$last_line_ftd   = <FH_FTDS>;
$last_line_date  = <FH_DATES>;


# output FTD header
my $outln = $last_line_ftd;
print FH_OUT_FTDS $outln;

$last_line_ftd   = <FH_FTDS>;
$last_line_date  = <FH_DATES>;

# output FTD (first line)
$outln = $last_line_ftd;
print FH_OUT_FTDS $outln;


# get FTD date
print "first ftd line : \n";
print $last_line_ftd;

my $date_ftd = "";
if ($last_line_ftd =~ m/^([0-9]{4}-[0-9]{2}-[0-9]{2})/){
#	print "match : "; 
#	print "ftd date : ";
	$date_ftd = $1;
}
#print $date_ftd;
#print "\n\n";


# get reference date
my $date_line = "";
if ($last_line_date =~ m/^([0-9]{4}-[0-9]{2}-[0-9]{2})/){
#	print "match : "; 
#	print "date data : ";
	$date_line = $1;
}
#print $date_line;
#print "\n\n";

if ($date_ftd ne $date_line) {
	print "aligning ...\n";
}
while ($date_ftd ne $date_line) {
	$last_line_date  = <FH_DATES>;
	if (eof(FH_DATES)) {
		print "ERROR : date file needs a start date at or before : ";
		print $date_ftd;
		print "\n";
		
		print "date data line : \n";
		print $last_line_date;
		print "\n";
		
		# close files, and quit
		close(FH_DATES);
		close(FH_FTDS);
		close(FH_DATES);
		close(FH_OUT_FTDS);
		if ($argc == 4) {
			close(FH_SKIP_DATES);
		}
		die;
	}
	if ($last_line_date =~ m/^([0-9]{4}-[0-9]{2}-[0-9]{2})/){
		$date_line = $1;
	}
}
print "aligned ...\n";
print "date data line \n";
print $last_line_date;
print "\n\n";

my $skip_line = 0;

# ---- dates are now aligned ----
while ($last_line_ftd = <FH_FTDS>) {
	if ($last_line_ftd =~ m/^([0-9]{4}-[0-9]{2}-[0-9]{2})/){
		$date_ftd = $1
	}
	
	$last_line_date  = <FH_DATES>;
    if ($last_line_date =~ m/^([0-9]{4}-[0-9]{2}-[0-9]{2})/){
		$date_line = $1;
    }
    
    $outln = "";
    if ($date_ftd ne $date_line) {
 	    #--- dates are NOT aligned again, so align, and output data until aligned
		while ($date_ftd ne $date_line) {
			# --- first print a 0 volume line
			$outln = $date_line;
			$outln .= ",,,0,\n";
	    	print FH_OUT_FTDS $outln;

			# update date line, (for recheck -> next time thru while ($date_ftd ne $date_line) loop)
			
			# check for going past end of last date
			if (eof(FH_DATES)) {
				print "ERROR : end of date file reached.  The date file is too short.\n";
				print "could not find ftd date in date file : ";
				print $date_ftd;
				print "\n";
						
				# close files, and quit
				close(FH_DATES);
				close(FH_FTDS);
				close(FH_DATES);
				close(FH_OUT_FTDS);
				if ($argc == 4) {
					close(FH_SKIP_DATES);
				}
				die;
			}
	
			$last_line_date  = <FH_DATES>;
			if ($last_line_date =~ m/^([0-9]{4}-[0-9]{2}-[0-9]{2})/){
				$date_line = $1;
				
				# if printing out a skipline file, then do it here ...
				$outln = $date_line;
				$outln .= "\n";
				if ($argc == 4) {
			    	print FH_SKIP_DATES $outln;					
				}
				# output to user that skip data is inserted / needed at this date
				print "FTD skip date inserted : ";
				print $outln;
				$skip_line++;
			}
		}
    }
    #--- dates are aligned again, so output the data
	$outln = $last_line_ftd;
	print FH_OUT_FTDS $outln;

	
}
print "# lines inserted : ";
print $skip_line;



close(FH_FTDS);
close(FH_DATES);
close(FH_OUT_FTDS);
if ($argc == 4) {
	close(FH_SKIP_DATES);
}

print "\n\n";
print "complete - done\n";
print "\n\n";

