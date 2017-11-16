#!/usr/bin/perl -w

#======================================================#
#--- This Perl script sets up CAM-chem emissions for---#
#--- forecast runs.
#---    * downloads QFED CO
#---    * calls the NCL script to re-grid and create---#
#---      CAM-chem emissions                        ---#
#---    * uplopads new emissions to glade           ---#
#---    * emails errors or completion               ---#
#---                               rrb Apr 03, 2016 ---#
#======================================================#

`cd /net/modeling1/data14b/buchholz/qfed/orig_0.25/`;


#------------------------------
# determine dates of run and current time
chomp($current_date = `date +%Y%m%d`) ;
chomp($time = `date +%H`);
chomp($year = `date +%Y`) ;
chomp($m = `date +%m`) ;

#************************TEST***********************
$current_date = 20171101;

print "Assessing emission file for $current_date\n";  #DEBUG

#------------------------------
# set up locations
$dir = "/net/modeling1/data14b/buchholz/qfed/orig_0.25/co_$year/";
$fname = "*co.*$current_date*.nc4";
$ftp_address = "ftp://iesa:\@ftp.nccs.nasa.gov/aerosol/emissions/QFED/v2.5r1/0.25/QFED/Y$year/M$m/";

print "$ftp_address\n";  #DEBUG

#------------------------------
# open log to see last time processed
$proclog = "/net/modeling1/data14b/buchholz/qfed/orig_0.25/.emission_processlog";
open(IN, "<$proclog");
chomp(@lines = <IN>);
$processed = grep { /$current_date/ } @lines;
close(IN);

print "Is current date processed: $processed\n";  #DEBUG

#------------------------------
# Data download
open(OUT,">/net/modeling1/data14b/buchholz/qfed/orig_0.25/temp.out");
chomp($last_file = `ls $dir$fname*`);

if ($last_file ne '' && $processed == 0){
  # download there and not processed
  print OUT "Download completed, end file present: $last_file\n";
}
elsif ($last_file ne '' && $processed == 1){
  # download there and already processed
  print OUT "$current_date: Download already completed, Emissions already processed\n";

}
else{
  # download not there
  print OUT "$current_date, hour $time: Emissions neither downloaded or processed\n";
  print OUT "Downloading . . . \n";
  print OUT  "wget $ftp_address$fname\n";
     `wget -N -q -P $dir "$ftp_address$fname" `;
}


#------------------------------
# process the emission file
chomp($check_again = `ls $dir$fname*`);

if ($check_again ne '' && $processed == 0){
  # download there and not done
  print OUT "Processing still needed, performing . . .\n";
     # --- add in NCL processing script ---#;

  open(OUT2,">>$proclog");
  print OUT2 "processed $current_date\n";
  close(OUT2);
}

  close(OUT);
#------------------------------
#send to glade at 10 pm
if ($time == 22 && $processed == 1){

}

#------------------------------
#send email if processing not done by 1pm
if (($time == 13 || $time == 22)&& $processed == 0){
  $to = 'buchholz@ucar.edu';
  $from = 'buchholz@ucar.edu';
  $subject = 'QFED processing not done';
  $message = 'After 1pm, QFED processing not done for '. $current_date .', may need to manually process.';

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




