#!/bin/bash

#new is a file that has to have a list of the session names that have an rttm file
#eg
#cat new
#abreja
#acosal1

mapfile -t my_array < new

#echo "${my_array[@]}"

for x in "${my_array[@]}"; do
awk -v name=$x '{if ($2 == name) print $0}' rttm_modelnewb4PLDA > $x.rttm
perl /X/CARE/dscore/scorelib/md-eval-22.pl -1 -c 0.25 -M `pwd`/map_$x.txt -r /home/coder/suchitra/CARE/rttm/reference/$x.rttm -s /home/coder/suchitra/CARE/rttm/system/$x.rttm
done

python /X/CARE/recall.py > /X/CARE/test5
