#!/bin/bash

if [ $# -ne 0 ]
then
    echo """
This script runs copy_data.sh on multiple user and dataset tar files. It
expects to find a list of files to copy to tape in "user_files.txt" and
"dataset_files.txt" files inside TAPE_WORK_DIR (default: "$TAPE_WORK_DIR").


Usage:
    run_multiple.sh

"""
    exit 2
fi

for fstem in `cat ${TAPE_WORK_DIR}/user_files.txt ${TAPE_WORK_DIR}/dataset_files.txt`
do
    ${TAPE_SCRIPTS}/copy_data.sh ${fstem}
done
