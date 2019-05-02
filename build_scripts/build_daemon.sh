#!/usr/bin/env bash

in_file=$1
out_file=$2
ws_port=$3
install_dir=$4

function setVar {
    varName=$1
    val=$2
    sed -E "s|^(${varName} = )None(.*)$|\1${val}\2|g"
}
	
< ${in_file} \
    setVar INSTALL_DIR \"${install_dir}\" | \
    setVar PORT $ws_port > \
    ${out_file}
