#!/bin/bash

if [ $# -lt 2 ]
then
    echo """
This script takes the name of two tapes (a main tape and backup tape) and
moves metadata (.ncdu and .sha512) files to the appropriate places
to document where tar files have been stored on tape.

This script reads from "user_files.txt" and "dataset_files.txt" files
in TAPE_WORK_DIR (default: "$TAPE_WORK_DIR") to decide which files are to be
documented and where. Files and symlinks will be stored in TAPE_TRACKING_DIR
(default: "$TAPE_TRACKING_DIR").

This script will also ensure all files are owned by TAPE_USER
(default: "$TAPE_USER") and TAPE_GROUP (default: "$TAPE_GROUP") and if
USE_GIT (default: "$USE_GIT") is set will commit all new files as TAPE_USER.


Usage:
    track_tapes.sh <tape_label> <backup_tape_label>
"""
    exit 2
fi

tape=$1
backup_tape=$2

users=${TAPE_WORK_DIR}/user_files.txt
datasets=${TAPE_WORK_DIR}/dataset_files.txt

tape_out=${TAPE_TRACKING_DIR}/tapes/${tape}
backup_out=${TAPE_TRACKING_DIR}/backup_tapes/${backup_tape}


check_dir () {
    local cur_dir=$1
    if [ ! -e ${cur_dir} ]
    then
        echo "Making directory ${cur_dir}"
        mkdir ${cur_dir}
        chown ${TAPE_USER}:${TAPE_GROUP} ${cur_dir}
    fi
}

drop_num() {
    # Drop the part number from the end of a file stem
    fstem=$1
    echo ${fstem%-[0-9][0-9]}
}

get_id () {
    # Get the user or dataset name (i.e. drop the date and part number)
    fstem=$1
    stem=$(drop_num $fstem)
    # Drop the date str
    ident=${stem#*_}
    echo $ident
}

get_summary_file () {
    fstem=$1
    no_part=$(drop_num $fstem)
    echo "${no_part}-all.ncdu"
}

populate_folders () {
    in_file=$1
    type=$2

    while read fstem
    do
        # Set correct ownership of files
        chown ${TAPE_USER}:${TAPE_GROUP} ${TAPE_WORK_DIR}/${fstem}.*

        # Move documentation files to tape dir
        mv ${TAPE_WORK_DIR}/${fstem}.{ncdu,sha512} ${tape_out}/

        all_file=${TAPE_WORK_DIR}/$(get_summary_file ${fstem})
        if [ -e ${all_file} ]
        then
            mv ${all_file} ${tape_out}/
        fi

        # Make symlinks in user or dataset folder
        ident=$(get_id ${fstem})
        out=${TAPE_TRACKING_DIR}/${type}/${ident}
        check_dir ${out}
        cd ${out}

        src_tape="../../tapes/${tape}/$(drop_num ${fstem})"
        for item in `ls ${src_tape}*`
        do
            if [ ! -e "${out}/$(basename $item)" ]
            then
                ln -s ${item} ${out}
                chown -R ${TAPE_USER}:${TAPE_GROUP} "${out}/$(basename $item)"
            fi

            if [ ! -e "${backup_out}/$(basename $item)" ]
            then
                ln -s ${item} ${backup_out}
                chown -R ${TAPE_USER}:${TAPE_GROUP} "${backup_out}/$(basename $item)"
            fi
        done

    done < ${in_file}
}



check_dir ${tape_out}
check_dir ${backup_out}

if [ -e ${users} ]
then
    populate_folders ${users} "users"
fi

if [ -e ${datasets} ]
then
    populate_folders ${datasets} "datasets"
fi

# Update git if in use
if [[ -v USE_GIT ]]
then
    su ${TAPE_USER} -c "git add ${tape_out} ${backup_out} ${users} ${datasets}"
    su ${TAPE_USER} -c "git commit -m Updating ${tape} ${backup_tape}"
fi