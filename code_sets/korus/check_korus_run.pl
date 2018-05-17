#!/usr/bin/perl -w

#======================================================#
#--- This Perl script checks the CAM-chem forecast  ---#
#--- for today and submits plotting HPC script      ---#
#--- if files are available                         ---#
#---                               rrb Apr 03, 2016 ---#
#======================================================#

`cd /glade/u/home/buchholz/NCL_programs/korus/`;

#------------------------------
# location of CAM-chem output
$dir = "/glade/scratch/barre/archive/KORUS_forecast_3inst/atm/hist/";
$fname = "KORUS_forecast_3inst.cam_0001.h1.";

#------------------------------
# determine dates of run and current time
chomp($current_date = `date +%Y-%m-%d`) ;
chomp($forecast_end = `date --date='$current_date +5 day' +%Y-%m-%d`);
chomp($time = `date +%H`);

#print "Checking files for $current_date to $forecast_end\n";

#------------------------------
# open plotlog to see last time plotted
$plotlog = "/glade/u/home/buchholz/NCL_programs/korus/.korus_plotlog";
open(IN, "<$plotlog");
chomp(@lines = <IN>);
close(IN);
$plotted = grep { /$current_date/ } @lines;

#------------------------------
# check if forecast is done and plot or not
open(OUT,">/glade/u/home/buchholz/NCL_programs/korus/temp.out");
chomp($end_file = `ls $dir$fname$forecast_end*`);

if ($end_file ne '' && $plotted == 0){
  # forecast there and not done
  print OUT "Forecast completed, end file present: $end_file\n";
  print OUT "Submitting plot script\n";
  `bsub < /glade/u/home/buchholz/NCL_programs/korus/submit_script`;
  open(OUT2,">>$plotlog");
  print OUT2 "plotted $current_date\n";
  close(OUT2);
}
elsif ($end_file ne '' && $plotted == 1){
  # forecast there and already done
  print OUT "$current_date, $time hour: Forecast already completed\n";
}
else{
  # forecast not there
  print OUT "$current_date, $time hour: Forecast not completed\n";
}
  close(OUT);

#------------------------------
#send email if plotting not done after 5 pm
if (($time == 17 || $time == 22)&& $plotted == 0){
  $to = 'buchholz@ucar.edu';
  $from = 'buchholz@ucar.edu';
  $subject = 'KORUS-AQ plotting not done';
  $message = 'After 4pm, KORUS-AQ plotting not done for '. $current_date .', may need to manually plot.';
 
  open(MAIL, "|/usr/sbin/sendmail -t");
 
  # Email Header
  print MAIL "To: $to\n";
  print MAIL "From: $from\n";
  print MAIL "Subject: $subject\n\n";
  # Email Body
  print MAIL $message;

  close(MAIL);
  print "Email Sent Successfully\n";
}

#------------------------------
#clean up at 10 pm
if ($time == 22 && $plotted == 1){
  `rm -f /glade/u/home/buchholz/NCL_programs/korus/CAM-chem*.png`;
}


