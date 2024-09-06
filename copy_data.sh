#!/bin/bash

set -e

# This should be a file name, no extension, no path
fname=$1

work_dir=/archive/new_tapes/workspace
pull_dir=${work_dir}/pull_test
scripts=/projects/dawn/sysadm-tools/tape_scripts
hash_node=deckard.camhres.ca

# make the copy on tape
cp ${work_dir}/${fname}.tar* /mnt/ltfs/
# Pull it back to test correctness and readability of copy
cp /mnt/ltfs/${fname}.* ${pull_dir}/

# Kick off the hashing from deckard
sudo -i -u localadmin ssh ${hash_node} "cd ${pull_dir}; sudo nohup sha512sum --check ${fname}.tar.sha512 > ${fname}.log 2> ${fname}.err < /dev/null &"
