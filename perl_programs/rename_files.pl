#!/usr/bin/perl -w

#======================================================#
#--- This Perl script renames ncl files for KORUS   ---#
#---                               rrb Apr 03, 2016 ---#
#======================================================#

chomp(@files_in = `ls *east_asia*`);

for (@files_in){
  $out_name = $_;  
  $out_name =~ s/east_asia/asia/g;
  print "$_ to $out_name\n";
  `mv $_ $out_name`;
  }
