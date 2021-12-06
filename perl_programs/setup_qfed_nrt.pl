#!/usr/bin/perl -w

#======================================================#
#--- This Perl script sets up CAM-chem emissions for---#
#--- forecast runs.                                 ---#
#---    * downloads QFED CO2 NRT                    ---#
#---    * calls the NCL script to re-grid and create---#
#---      CAM-chem emissions                        ---#
#---    * wites over time slice in year files       ---#
#---    * uplopads new emissions to glade           ---#
#---    * emails errors or completion               ---#
#---                               rrb Apr 03, 2016 ---#
#======================================================#

#$topdir = "/net/modeling1/data14b/buchholz/qfed/orig_0.25";
$topdir = "/data14b/buchholz/qfed/orig_0.25";
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
chomp($min = `date +%M`);
chomp($year = `date --date='$today -1 day' +%Y`) ;
chomp($month = `date --date='$today -1 day' +%m`) ;

# Use next line if you need to overwrite
#$current_date = 20210228;

open(OUT,">$topdir/temp.out");
print OUT "Assessing emission file for $current_date\n";  #DEBUG


#------------------------------
# set up locations
$dir = "$topdir/co2_nrt/";
$fname = "qfed2.emis_co2.006.$current_date.nc4";
#$ftp_address = "ftp://ftp.nccs.nasa.gov/qfed/0.25_deg/Y$year/M$month/";
$http_address = "https://portal.nccs.nasa.gov/datashare/gmao/qfed/0.25_deg/Y$year/M$month/";

#print OUT "$ftp_address\n";                               #DEBUG
print OUT "$http_address\n";                               #DEBUG


#------------------------------
# open log to see last time processed
$proclog = "$topdir/.emission_processlog";
open(IN, "<$proclog");
chomp(@lines = <IN>);
$processed = grep { /$current_date/ } @lines;
close(IN);

print OUT "Is current date processed: $processed\n";      #DEBUG


#------------------------------
# Data download
chomp($last_file = `ls $dir$fname*`);
chomp($now = `date`);

if ($last_file ne '' && $processed == 0){
  # download there and not processed
  print OUT "$now : Download completed, end file present: $last_file\n";
}
elsif ($last_file ne '' && $processed == 1){
  # download there and already processed
  print OUT "$now : Download already completed, Emissions already processed\n";
}
else{
  # download not there
  print OUT "$now : Emissions neither downloaded or processed\n";
  print OUT "Downloading . . . \n";
  #print OUT  "wget --user=gmao_ops --password= -N -q -P $dir $ftp_address$fname\n";
  #   `wget --user=gmao_ops --password= -N -q -P $dir "$ftp_address$fname" `;
  print OUT  "wget -nd -r --no-parent -N -q -P $dir $http_address$fname \n";
             `wget -nd -r --no-parent -N -q -P $dir $http_address$fname`;
}


#------------------------------
# process the emission file
chomp($check_again = `ls $dir$fname*`);
#$codehome = "/home/buchholz/Documents/code_database/ncl_programs/data_processing";
$codehome = "/home/buchholz/code_database/ncl_programs/data_processing";


if ($check_again ne '' && $processed == 0){
  # download there and not done
  print OUT "Processing still needed, performing . . .\n";

     # --- call to NCL processing script ---#
     print OUT "/usr/local/ncarg/bin/ncl YYYYMMDD=$current_date  NRT=True $codehome/combine_qfed_finn_ers.ncl > $topdir/out.dat\n";            #DEBUG

     `/usr/local/ncarg/bin/ncl YYYYMMDD=$current_date NRT=True $codehome/combine_qfed_finn_ers.ncl > $topdir/out.dat`;

  print OUT "Splitting OC and BC . . .\n";
     # --- shell script ---#
     `/usr/local/ncarg/bin/ncl 'tracer="BC"' 'year="2020_2022"' NRT=True 'outres="0.9x1.25"' 'emiss_type="from_co2"' $codehome/redistribute_emiss.ncl >> $topdir/out.dat\n`;
     `/usr/local/ncarg/bin/ncl 'tracer="OC"' 'year="2020_2022"' NRT=True 'outres="0.9x1.25"' 'emiss_type="from_co2"' $codehome/redistribute_emiss.ncl >> $topdir/out.dat\n`;
     `/usr/local/ncarg/bin/ncl 'tracer="VBS"' 'year="2020_2022"' NRT=True 'outres="0.9x1.25"' 'emiss_type="from_co2"' $codehome/redistribute_emiss.ncl >> $topdir/out.dat\n`;
     `/usr/local/ncarg/bin/ncl 'tracer="SOAG"' 'year="2020_2022"' NRT=True 'outres="0.9x1.25"' 'emiss_type="from_co2"' $codehome/redistribute_emiss.ncl >> $topdir/out.dat\n`;
     `/usr/local/ncarg/bin/ncl 'tracer="SO4"' 'year="2020_2022"' NRT=True 'outres="0.9x1.25"' 'emiss_type="from_co2"' $codehome/redistribute_emiss.ncl >> $topdir/out.dat\n`;
  print OUT "/usr/local/ncarg/bin/ncl 'tracer=\"BC\"' 'year=\"2020_2022\"' NRT=True 'outres=\"0.9x1.25\"' 'emiss_type=\"from_co2\"' $codehome/redistribute_emiss.ncl >> $topdir/out.dat\n";      #DEBUG
}
else{
  print OUT "File still not available . . .\n";
}



#------------------------------
#Check Processed and send e-mail
chomp($current_date_check = `date --date='$today +9 day' +%Y%m%d`);
#$current_date_check = $current_date+10;
print OUT "Checking: $current_date_check\n";    #DEBUG
chomp(@check_file = `/usr/local/ncarg/bin/ncl YYYYMMDD=$current_date_check $codehome/check_emiss.ncl`);
#print"/usr/local/ncarg/bin/ncl year=$year YYYYMMDD=$current_date $codehome/check_emiss.ncl\n";

$proc_file = grep { /True/ } @check_file;

print OUT "Is current date processed yet: $proc_file\n";    #DEBUG
print OUT "@check_file\n";                                  #DEBUG

if ($processed == 0 && $proc_file == 1){
    print OUT "Checked: all files have some non-zero values for $current_date \n";
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
    print OUT "***** Processed, email sent successfully *****\n";

   #------------------------------
   #send to glade after 1am
   if ($time >= 1 && $min >= 01){
   `scp /data14b/buchholz/qfed/cam_0.9x1.25/from_co2/nrt_new/*2020_2022.nc buchholz\@data-access.ucar.edu:/glade/work/buchholz/emis/qfed_finn_nrt_1x1/`;
       print OUT "Sent to cheyenne. \n";
   }
}
elsif ($processed == 1 && $proc_file == 1){
    print OUT "Processed and email already sent. \n";
   #------------------------------
   #send to glade after 1am
   if ($time >= 1 && $min >= 01 && $time<=8){
   `rsync -t /data14b/buchholz/qfed/cam_0.9x1.25/from_co2/nrt_new/*2020_2022.nc buchholz\@data-access.ucar.edu:/glade/work/buchholz/emis/qfed_finn_nrt_1x1/`;
       print OUT "Sent to cheyenne at $time. \n";
   }
}
else{
    print OUT "Not processed yet. \n";
}

#------------------------------
#send email if processing not done by 8am
if ($time == 8 && $processed == 0){
  $subject = 'QFED processing not done';
  $message = 'After 8am, QFED processing not done for '. $current_date .', may need to manually process.';

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

  close(OUT);

