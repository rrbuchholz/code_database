#!/usr/bin/perl -w

#======================================================#
#--- This Perl script renames files                 ---#
#---                               rrb Apr 03, 2016 ---#
#======================================================#

$dir = "/amadeus-data/cam-chem/2019";
$matchstring = "branch02.";
$replacestring = "";

chomp(@files_in = `ls $dir/*`);
print "@files_in\n";

for (@files_in){
  $out_name = $_;  
  $out_name =~ s/$matchstring/$replacestring/g;
  print "$_ to $out_name\n";
  `mv $_ $out_name`;
  }
