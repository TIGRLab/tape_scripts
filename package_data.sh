#!/bin/bash
#
# This takes an input folder intended for archive and generates a tarball and
# .ncdu and .sha512 files for the contents at the location given
#
# The input folder and current date will be used to generate the file names
# so the input folder should be named correctly.

if [ $# -lt 2 ]
then
    echo "Usage: package_data.sh <in_dir> <out_dir>"
    echo "          e.g. package_data.sh /mnt/tigrlab/to_tape/ARCHIVE5/2024-06-01_anthony /archive/new_tapes/tapes/KM0001"
    exit 2
fi


in_dir=$1
out_dir=$2

cd ${in_dir}

# Remove quotations from file names
find . -name "*'*" -exec bash -c $'for f; do mv "$f" "${f//\\\047/}"; done' _ {} +

# Switching to expecting user to set date on folder name
#fname=$(date '+%Y-%m-%d')_${PWD##*/}
fname=$(basename $in_dir)
out_path=${out_dir}/${fname}

ncdu -x -o ${out_path}.ncdu ./

# Hash only
# find * -type f -exec sha512sum --tag {} + > ${out_path}.sha512

# tar and hash
tar --format=posix -cvpWf ${out_path}.tar * | grep -v -e ^Verify -e /$ | xargs -I '{}' sh -c "test -f '{}' && sha512sum --tag '{}'" >> ${out_path}.sha512

# Hash whole tarball as well, allows faster verification of copies
cd ${out_dir}
sha512sum --tag ./$(basename ${out_path}).tar >> ${out_path}.tar.sha512
