#!/bin/csh -f
# usage: caldera.csh 
# #        logs onto any node
# # or
# # usage ./caldera.csh caldera04 
# #      where caldera04 logs you ito caldera node 04
#

if ($#argv == 0) then
   bsub -XF -Is -q caldera -W 12:00 -n 1 -P UESM0003 /bin/tcsh
endif

if ($#argv == 1) then
   bsub -XF -Is -q caldera -m $1 -W 12:00 -n 1 -P UESM0003 /bin/tcsh
endif
