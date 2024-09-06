#!/bin/bash

scripts=/projects/dawn/sysadm-tools/tape_scripts

for fstem in `cat ${scripts}/user_files.txt ${scripts}/dataset_files.txt`
do
    ${scripts}/copy_data.sh ${fstem}
done

#while read fstem
#do
#    ${scripts}/copy_data.sh ${fstem}
#done < ${scripts}/user_files.txt

#while read fstem
#do
#    ${scripts}/copy_data.sh ${fstem}
#done < ${scripts}/dataset_files.txt
