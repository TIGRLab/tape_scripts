#!/bin/bash

if [ $# -lt 3 ]
then
    echo """
This script takes:
  - An input directory of folders that must be split into equal sized groups

  - An output template path, where the string 'GROUPNUM' will be replaced by
    an incremented number as output folder groups are generated.
    For example, giving ./2025-09-23_OPT-GROUPNUM/pipelines/ABCD will split the
    input folders into output paths like:
          ./2025-09-23_OPT-01/pipelines/ABCD
          ./2025-09-23_OPT-02/pipelines/ABCD
          ...
          ./2025-09-23_OPT-N/pipelines/ABCD

  - The number of groups to split the input folders into

  - [OPTIONAL] The number to start counting from (exclusive). Defaults to 0 (
    i.e. the first output group will be labelled '1').

Usage:

    split_folders.sh <in_dir> <output_prefix> <num_groups> [<start_range>]


"""
    exit 2
fi

# in_dir should be a full path to a folder of subfolders you want
# to move to equal-ish sized (by num not file size) destination directories
in_dir=${1}

# The prefix to use for all of the destination directories.
# The prefix should be formatted so that one of the folders
# contains a -GROUPNUM string to replace with the intended dest
# group number. E.g. (YYYY-MM-DD_FOLDER-GROUPNUM/sub/dir/here that
# becomes FOLDER-01, FOLDER-02, etc. with the rest of the path
# remaining unchanged)
dest_template=${2}

# The number of groups you want to split in_dir into.
num_split=${3}

# Optional starting range to use for the group numbers.
# if unset, will use 0. Note this is exclusive (e.g. if 10,
# the first group folder will start at 11)
start_num=${4:-0}

counter=0
for subdir in `find ${in_dir} -mindepth 1 -maxdepth 1 -printf "%P\n"`
do
  if [[ ${counter} == ${num_split} ]]
  then
    counter=0
  fi

  group=$(( counter + start_num + 1 ))
  padded_group=$(printf '%02d' ${group})

  dest_path="${dest_template/-GROUPNUM/-$padded_group}"
  if [ ! -e ${dest_path} ]
  then
    mkdir -p ${dest_path}
    chown -R clevis:kimel ${dest_path}
  fi

  mv "${in_dir}/${subdir}" "${dest_path}/"

  ((counter++))

done
