#!/bin/bash

tape=$1
backup_tape=$2

if [ $# -lt 2 ]
then
    echo "Usage: track_tapes.sh <tape_label> <backup_tape_label>"
    echo "          e.g. track_tapes.sh KM0001 KM0002"
    exit 2
fi

script_dir=/projects/dawn/sysadm-tools/tape_scripts
tape_dir=/archive/new_tapes
workdir=${tape_dir}/workspace

users=${script_dir}/user_files.txt
datasets=${script_dir}/dataset_files.txt

tape_out=${tape_dir}/tapes/${tape}
backup_out=${tape_dir}/backup_tapes/${backup_tape}


check_dir () {
    local cur_dir=$1
    if [ ! -e ${cur_dir} ]
    then
        echo "Making directory ${cur_dir}"
        mkdir ${cur_dir}
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
    ident=${stem##*_}
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
        # Move documentation files to tape dir
        mv ${workdir}/${fstem}.{ncdu,sha512} ${tape_out}/

        all_file=${workdir}/$(get_summary_file ${fstem})
        if [ -e ${all_file} ]
        then
            mv ${all_file} ${tape_out}/
        fi

        # Make symlinks in user or dataset folder
        ident=$(get_id ${fstem})
        out=${tape_dir}/${type}/${ident}
        check_dir ${out}
        cd ${out}

        src_tape="../../tapes/${tape}/$(drop_num ${fstem})"
        for item in `ls ${src_tape}*`
        do
            if [ ! -e "${out}/$(basename $item)" ]
            then
                ln -s ${item} ${out}
            fi

            if [ ! -e "${backup_out}/$(basename $item)" ]
            then
                ln -s ${item} ${backup_out}
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
