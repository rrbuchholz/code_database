#!/bin/csh -f
#
# Script to create, build and run a CESM case
#

set echo verbose

# Case description, locations
set CASENAME = cesm1_2_2.test
set CASEDIR  = ~/cesm_case/$CASENAME            #will be created by create_newcase

# ------------------
#  Which steps you want this script to do now
# ------------------

set do_create_newcase  = 1   # 1 = do create_newcase, 0 = skip create_newcase
set do_configure       = 1   # 1 = do configure     , 0 = skip configure
set do_build           = 1   # 1 = do build         , 0 = skip build
set do_run             = 1   # 1 = submit run       , 0 = skip submit run 

set overwrite_existing = 0  # 1 = If case currently exists, WILL overwrite
			    # 0 = If case currently exists, will NOT overwrite (create or configure)
                             


#    If you need to stop the script to edit files and then resume it:
#    step 1: run this script with set do_create_newcase = 1
#                                 set do_configure      = 1
#				  set do_build          = 0
#				  set do_run            = 0
#    step 2: make changes (like add code to SourceMods or modify data sets)
#    step 3: run this script with set do_create_newcase = 0
#                                 set do_configure      = 0
#				  set do_build          = 1
#				  set do_run            = 1


# ------------------
#  Directories 
# ------------------

# This is just for reference in this script;
# changing RUNDIR here won't change build or rundir in the CESM scxripts.
# You could figure out how to use this setting in the configure process so it does take effect!
#
set BLDDIR = /glade/scratch/$LOGNAME/$CASENAME/bld   #set in env_build.xml as EXEROOT
set RUNDIR = /glade/scratch/$LOGNAME/$CASENAME/run   

# source code/build scripts for the model version we're running
set cesm_collection = /glade/p/cesm/tutorial/cesm1_2_2.tutorial

# ------------------
# 1) create_newcase 
# ------------------

if ( $do_create_newcase ) then

    # Only call create_newcase if a) case doesn't exist already or b) it does and should be overwritten
    if (( ! -d $CASEDIR ) || ( ( ! -d $CASEDIR ) && ( $overwrite_existing == 1 ) ) ) then
	cd $cesm_collection/scripts
	./create_newcase -case $CASEDIR -res T31_T31 -compset F_2000_CAM5 -mach yellowstone
	if ( ! -d $CASEDIR ) exit -1

    else
	echo "-------- WARNING: CASEDIR $CASEDIR already exists."
	echo "Skipping create_newcase. To force, set overwrite_existing in $0"
    endif # -d $CASEDIR /overwrite_existing

endif

# ------------------
# 2) configure 
# ------------------

if ( $do_configure ) then

    # Only call configure if a) case doesn't exist already or b) it does and should be overwritten
    set test = 
    if ( -e $CASEDIR/CaseStatus ) set test = `grep configured $CASEDIR/CaseStatus`
    if (( $#test == 0 ) || ( ( $#test == 0 ) && ( $overwrite_existing == 1 ) ) ) then
	cd $CASEDIR
	./cesm_setup
	if ( $status == 0 ) then
	    echo "case configured" >> & $CASEDIR/CaseStatus
	else
	    echo "ERROR: $0 cesm_setup"
	    exit -1
        endif
    else
	echo "-------- WARNING: $CASEDIR/CaseStatus indicates case already set up"
	echo "$test"
	echo "Skipping cesm_setup. To force, set overwrite_existing in $0"
    endif # -d $CASEDIR/CaseStatus shows already created /overwrite_existing

endif

# ------------------
# 3) build
# ------------------

#Build is smart enough to only re-do what needs re-doing, so no harm in calling it again 
#even if it's been done before.
if ( $do_build ) then
    cd $CASEDIR
    ./$CASENAME.build
endif


# ------------------
# 4) run
# ------------------

if ( $do_run ) then

    cd $CASEDIR

    # quit if executable does not exist
    ls $BLDDIR/cesm.exe
    if ( ! -x $BLDDIR/cesm.exe ) then
	echo "-------- ERROR: do_run = $do_run in $0 but executable $BLDDIR/cesm.exe does not exist"
	exit -1
   endif

    # quit if there is already a case running with this name
    set test = `bjobs -J $CASENAME`
    if ( $#test > 0 ) then
	echo "--------ERROR: bjobs -J $CASENAME found job with this name already running"
	echo "NOT RUNNING JOB. To override, comment out exit after bjobs logic in $0"
	exit -1
    endif


   # ------------- Change run settings --------------------------
   # change run time to 2 months
   ./xmlchange STOP_N=2,STOP_OPTION=nmonths

    # add variables to namelist: user_nl_cice
    set nl_file = user_nl_cice
    set test = `grep kmt $nl_file`
    if ( $#test == 0 ) then
	echo "grid_file = '/glade/p/cesm/cseg/inputdata/share/domains/domain.ocn.48x96_gx3v7_100114.nc'" >> $nl_file
	echo "kmt_file = '/glade/p/cesm/cseg/inputdata/share/domains/domain.ocn.48x96_gx3v7_100114.nc'" >> $nl_file
    endif



   #
   # -------------- Use 'sed' to change things in the run script 
   #      
   # This is set up for my account (bundy) for testing purposes; you shouldn't need it
   # for the tutorial but it may be useful if you want to see how to change things (ie. wall clock, queue)
   #
    if ( $LOGNAME == bundy ) then
	# change project number
	set proj = P93300642                                 #project number to use
	set PROJ=`grep BSUB $CASENAME.run | grep -e '-P' `   #line in file with existing project number 
	echo;   echo $PROJ[3]                                #pull out the exact project number to replace
	rm -f temp2 ; sed s/$PROJ[3]/$proj/ < $CASENAME.run > temp2   #replace it, into a temporary file
	\cp $CASENAME.run $CASENAME.run.orig                 #backup original run file
	\cp temp2  $CASENAME.run                             #copy temp file to run file

	# comment out dedicated queue
	# OLD #BSUB -U CESM_WS
	# NEW ##BSUB -U CESM_WS

	rm -f temp2 ; sed s/"BSUB -U"/"#BSUB -U"/ < $CASENAME.run > temp2   #replace it, into a temporary file
	\cp $CASENAME.run $CASENAME.run.orig                 #backup original run file
	\cp temp2  $CASENAME.run                             #copy temp file to run file


   endif  #LOGNAME bundy

#    echo "not submitting..."
    ./$CASENAME.submit
    echo "Submitted job. Use 'bjobs' to view in the queue; check email if it is not found there."


endif


echo "Succesful exit of $0"








