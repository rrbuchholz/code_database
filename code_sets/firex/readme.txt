#####################################################################
# Collection of scripts and data requred for the KORUS
# campaign, April - June 2016.
#                                                  r.r.b 2016-04-25
#####################################################################

---------------------------------------------------------------------
altitude_ts_plot.ncl     : Plot altitude vs time at each station
    > calls colormaps/GMT_wysiwygcont_rrb.rgb

---------------------------------------------------------------------
curtain_plot.nc          : Plot curtains along specified trajectories
    > calls countries.shp
            KOR_adm1.shp
            colormaps/GMT_wysiwygcont_rrb.rgb

---------------------------------------------------------------------
lat_lon_plot.ncl         : Plot maps
    > calls countries.shp
            KOR_adm1.shp
            colormaps/GMT_wysiwygcont_rrb.rgb

---------------------------------------------------------------------
firex_wrapper.ncl        : calls other plotting routines 
                                 altitude_ts_plot.ncl
                                 curtain_plot.nc     
                                 lat_lon_plot.ncl    
                           and loops over tracers, chooses regions etc

---------------------------------------------------------------------
submit_script            : batch script to submit as bsub
                                 bsub < submit_script
                           defines date and distributes across nodes

---------------------------------------------------------------------
check_forecast_run.pl       : Used by crontab
                          */20 10-17 * * *   . /etc/profile.d/lsf.sh; /$path$/check_korus_run.pl
  > creates temp.out     : Can access at any time for  outcome of
                           last run of check_korus_run.pl
  > writes to .korus_plotlog
                         : Adds a date for current day if perform plot

---------------------------------------------------------------------
map_plot.ncl             : Maps the ground sites of KORUS
    > calls countries.shp
            KOR_adm1.shp
            KORUS_ground_sites.csv

