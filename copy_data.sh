#!/bin/bash

set -e

if [ $# -lt 1 ]
then
    echo """
This script copies a tarball and its .tar.sha512 file onto tape. Must be run
from tigrsrv with the correct tape already mounted. See our admin docs
for more info on inserting and mounting a tape:
https://github.com/TIGRLab/admin/wiki/Tape-Drive

The script takes a file name without an extension or preceding path. It will
copy the files to tape, and then read them back from tape and hash the copy
to ensure the tape copy is identical and readable (DON'T try to skip this step
to save time!).

Env vars read by this script:
    - TAPE_WORK_DIR: where the original file is expected to be found
        (default: "$TAPE_WORK_DIR")
    - TAPE_PULL_DIR: The directory to pull the file to and store the results
        of hashing it. (default: "$TAPE_PULL_DIR")
    - TAPE_SCRIPTS: The directory other tape scripts can be found in.
        (default: "$TAPE_SCRIPTS")
    - HASH_NODE: The node on our network to use when hashing data
        (default: "$HASH_NODE")

Usage:

    copy_data.sh <file_name>

"""
    exit 2
fi

# This should be a file name, no extension, no path
fname=$1

# make the copy on tape
cp ${TAPE_WORK_DIR}/${fname}.tar* /mnt/ltfs/

# Pull it back to test correctness and readability of copy
cp /mnt/ltfs/${fname}.* ${TAPE_PULL_DIR}/

# Kick off the hashing to ensure the tape copy is correct
sudo -i -u localadmin ssh ${HASH_NODE} "cd ${TAPE_PULL_DIR}; sudo nohup sha512sum --check ${fname}.tar.sha512 > ${fname}.log 2> ${fname}.err < /dev/null &"
