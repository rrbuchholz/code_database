#!/bin/csh -f
# usage: geyser.csh 
#        logs onto any node
# or
# usage ./geyser.csh geyser04 
#      where geyser04 logs you ito geyser node 04

if ($#argv == 0) then
   bsub -XF -Is -q geyser -W 24:00 -n 1 -P P19010000 /bin/tcsh
endif

if ($#argv == 1) then
   bsub -XF -Is -q geyser -m $1 -W 24:00 -n 1 -P P19010000 /bin/tcsh
endif
