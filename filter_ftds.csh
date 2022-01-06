#!/bin/csh -f

# Copyright (c) 2022 : tonys357 at github
#    you may use this code, modify as desired, just include the copyright notice
#    code is delivered AS IS
#    not liable for any use, misuse, errors, or whatever, etc.
#    not liable for any errors, bugs, etc.
#    

# parse any args here ...
set show_info = false

if ($1 == "help") then
  set show_info = true
endif

if ($1 == "-h") then
  set show_info = true
endif

if ($1 == "?") then
  set show_info = true
endif

if ($#argv != 4) then
  set show_info = true
endif

# display help, how to use, etc ...
if ($show_info == true) then
  echo
  echo "filter_ftds.csh"
  echo "---------------"
  echo "extracts Failure-to-Deliver data of a particular symbol, from a directory of"
  echo "downloaded (and unpacked) FTD data from the SEC."
  echo
  echo "Syntax :"
  echo "filter_ftds.csh <dir> <hdr_data_file> <symbol> <output file>"
  echo 
  echo "  <dir>            : directory name of FTD data files downloaded from SEC and unzipped"
  echo "                     only FTD data files downloaded (and unpacked) from the SEC must"
  echo "                     be in this directory"
  echo "  <hdr_data_file>  : any filename in <dir>.  "
  echo "                     The first line is taken from this file, and used as a header line"
  echo "  <symbol>         : name of symbol to search for"
  echo "  <output file>    : output .csv file"
  echo 
  echo "an example command line is :"
  echo "./filter_ftds.csh cns_fails_from_sec cnsfails202101a.txt TRCH trch_ftds_2021.csv "
  echo
  exit 0
endif


### STEP 1 : create a temporary output file with a proper header
head -1 $1/$2 > tmp_out.txt

### STEP 2 : add only data with the stock symbol
grep -h "|$3|" $1/* >> tmp_out.txt

### STEP 3 : remove any commas from the name or description 
sed -e 's/,//g' tmp_out.txt > tmp_out2.txt

### STEP 4 : convert the delimiter -->  | -> ,     to get to CSV format
sed -e 's/|/,/g' tmp_out2.txt > tmp_out3a.csv

### STEP 5 : change the date into yyyy-mm-dd format (originally, was yyyymmdd format) 
### do this in 2 steps 
# - first change yyyy to yyyy-
sed -e 's/^[0-9]\{4\}/&-/g'  tmp_out3a.csv  > tmp_out3b.csv
# - next change yyyy-mm to yyyy-mm-
sed -e 's/^[0-9]\{4\}-[0-9]\{2\}/&-/g'   tmp_out3b.csv  > $4


### STEP 6 : clean up (delete all temporary files)
rm tmp_out.txt
rm tmp_out2.txt
rm tmp_out3a.csv
rm tmp_out3b.csv


