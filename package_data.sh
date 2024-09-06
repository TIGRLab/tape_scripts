#!/bin/bash

if [ $# -lt 2 ]
then
    echo """
This script packages data into a tarball for storage on tape. It will
generate:
    - A tarball containing everything from the input folder
    - A .ncdu file of the input folder
    - A .sha512 file containing hashes for each item in the input folder
    - A .tar.sha512 file containing a hash of the tarball itself

Quotes and spaces will be removed from files and folders. The input folder name
should be prefixed with the date to conform to our format. All outputs will use
the same name as the input folder.


Usage:

    package_data.sh <in_dir> <out_dir>

"""
    exit 2
fi


in_dir=$1
out_dir=$2

cd ${in_dir}

# Remove quotations from file names
find . -name "*'*" -exec bash -c $'for f; do mv "$f" "${f//\\\047/}"; done' _ {} +

# Set the destination path for output files
fname=$(basename $in_dir)
out_path=${out_dir}/${fname}

# Generate an ncdu file for the input folder
ncdu -x -o ${out_path}.ncdu ./

# tar and hash input folder
tar --format=posix -cvpWf ${out_path}.tar * | grep -v -e ^Verify -e /$ | xargs -I '{}' sh -c "test -f '{}' && sha512sum --tag '{}'" >> ${out_path}.sha512

# Hash whole tarball as well, allows faster verification of copies
cd ${out_dir}
sha512sum --tag ./$(basename ${out_path}).tar >> ${out_path}.tar.sha512
