#!/usr/bin/perl -w

#======================================================#
#--- This Perl script sets up CAM-chem emissions for---#
#--- forecast runs.                                 ---#
#---    * downloads QFED CO2 NRT                     ---#
#---    * calls the NCL script to re-grid and create---#
#---      CAM-chem emissions                        ---#
#---    * uplopads new emissions to glade           ---#
#---    * emails errors or completion               ---#
#---                               rrb Apr 03, 2016 ---#
#======================================================#

$topdir = "/net/modeling1/data14b/buchholz/qfed/orig_0.25";
`cd $topdir/`;

#------------------------------
# set up email correspondence
  $to = 'buchholz@ucar.edu';
  $from = 'buchholz@ucar.edu';

#------------------------------
# determine dates of run and current time
chomp($today = `date +%Y%m%d`) ;
chomp($current_date = `date --date='$today -1 day' +%Y%m%d`);
chomp($time = `date +%H`);
chomp($year = `date +%Y`) ;
chomp($m = `date +%m`) ;

#************************TEST***********************
print "Assessing emission file for $current_date\n";  #DEBUG

#------------------------------
# set up locations
$dir = "$topdir/co2_nrt/";
$camdir = "/net/modeling1/data14b/buchholz/qfed/cam_0.94x1.2/from_co2/nrt/";
$fname = "*co2.*$current_date*.nc4";
$ftp_address = "ftp://ftp.nccs.nasa.gov/qfed/0.25_deg/Y$year/M$m/";

print "$ftp_address\n";  #DEBUG

#------------------------------
# open log to see last time processed
$proclog = "$topdir/.emission_processlog";
open(IN, "<$proclog");
chomp(@lines = <IN>);
$processed = grep { /$current_date/ } @lines;
close(IN);

print "Is current date processed: $processed\n";  #DEBUG

#------------------------------
# Data download
open(OUT,">$topdir/temp.out");
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
  print OUT  "wget --user=gmao_ops --password= $ftp_address$fname\n";
     `wget -N -q -P $dir "$ftp_address$fname" `;
}

      $codehome = "/home/buchholz/Documents/code_database/ncl_programs/data_processing";
     print "ncl YYYYMMDD=$current_date $codehome/combine_qfed_finn_ers.ncl > $topdir/out.dat\n";

#exit
#------------------------------
# process the emission file
chomp($check_again = `ls $dir$fname*`);

if ($check_again ne '' && $processed == 0){
  # download there and not done
  print OUT "Processing still needed, performing . . .\n";
     # --- add in call to NCL processing script ---#
      $codehome = "/home/buchholz/Documents/code_database/ncl_programs/data_processing";
     `ncl YYYYMMDD=$current_date $codehome/combine_qfed_finn_ers.ncl > $topdir/out.dat`;

  chomp($last_file = `ls $dir$fname*`);
    open(OUT2,">>$proclog");
    print OUT2 "processed $current_date\n";
    close(OUT2);

    #send email once processed
    $subject = 'QFED '.$current_date.' processing complete';
    $message = '*** Completed processing QFED for use in CAM-chem for '. $current_date .'.';
    open(MAIL, "|/usr/sbin/sendmail -t");
    # Email Header
    print MAIL "To: $to\n";
    print MAIL "From: $from\n";
    print MAIL "Subject: $subject\n\n";
    # Email Body
    print MAIL $message;
    close(MAIL);
    print OUT "Email Sent Successfully\n";
}

  close(OUT);
#------------------------------
#send to glade at 5am
if ($time == 5 && $processed == 1){

}

#------------------------------
#send email if processing not done by 1pm
if (($time == 4 || $time == 10)&& $processed == 0){
  $subject = 'QFED processing not done';
  $message = 'After 4am, QFED processing not done for '. $current_date .', may need to manually process.';

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




