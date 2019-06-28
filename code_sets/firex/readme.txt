#####################################################################
# Collection of scripts and data requred for the FIREX
# campaign, June - August 2019.
#                                                  r.r.b 2019-06-24
#####################################################################

---------------------------------------------------------------------
firex_wrapper.ncl        : calls other plotting routines 
                         :        altitude_ts_plot.ncl
                         :        curtain_plot.nc     
                         :        lat_lon_plot.ncl    
                         : loops over tracers, chooses regions etc

example calls:
> ncl 'filename="/waccm-output/f.e21.FWSD.f09_f09_mg17.forecast.001.cam.h3.2019-06-29-00000.nc"' 'file_prefix="/waccm-output/f.e21.FWSD.f09_f09_mg17.forecast.001.cam.h3."' STATION=True forecast_date=20190621 firex_wrapper.ncl
> ncl 'filename="/waccm-output/f.e21.FWSD.f09_f09_mg17.forecast.001.cam.h3.2019-06-29-00000.nc"' CURTAIN=True forecast_date=20190621 firex_wrapper.ncl
> ncl 'filename="/waccm-output/f.e21.FWSD.f09_f09_mg17.forecast.001.cam.h3.2019-06-29-00000.nc"' LATLON=True forecast_date=20190621 firex_wrapper.ncl
---------------------------------------------------------------------
altitude_ts_plot.ncl     : Plot altitude vs time at each station
                         : calls colormaps/GMT_wysiwygcont_rrb.rgb
                         : calls read_in_species.ncl

---------------------------------------------------------------------
curtain_plot.nc          : Plot curtains along specified trajectories
                         : calls shape files
                         : calls colormaps/GMT_wysiwygcont_rrb.rgb
                         : calls read_in_species.ncl

---------------------------------------------------------------------
lat_lon_plot.ncl         : Plot maps
                         : calls shape files
                         : calls colormaps/GMT_wysiwygcont_rrb.rgb
                         : calls read_in_species.ncl

---------------------------------------------------------------------
read_in_species.ncl      : extracts tracer of interest and converts units

---------------------------------------------------------------------
submit_script            : batch script to submit as qsub
                         :        qsub < submit_script
                         : defines date and distributes across nodes
                         : via a command file

---------------------------------------------------------------------
check_forecast_run.pl    : Used by crontab
                          */20 10-17 * * *   . /etc/profile.d/lsf.sh; /$path$/check_forecast_run.pl
  > creates temp.out     : Can access at any time for outcome of
                           last run of check_korus_run.pl
  > writes to .korus_plotlog
                         : Adds a date for current day if perform plot

---------------------------------------------------------------------
map_plot.ncl             : Maps the ground sites of KORUS
                           Not in the automated routines
    > calls countries.shp
            KOR_adm1.shp
            KORUS_ground_sites.csv

