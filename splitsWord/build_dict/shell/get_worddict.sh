#!/bin/bash

if [ $# != 1 ]
then
    echo "usage: get_worddict.sh vocab"
    exit 0
fi

make clean

VOC_FILE=$1

python shell/mk_basic_dict.py $VOC_FILE $VOC_FILE.basic

#iconv -f gbk -t utf8 $VOC_FILE.basic > raw_utf8/basic/total.basic

if [ ! -d "raw_utf8/basic" ]
then
    mkdir -p raw_utf8/basic
fi

cp $VOC_FILE.basic raw_utf8/basic/total.basic

make

rm -rf worddict.${VOC_FILE}
mkdir worddict.${VOC_FILE}

cp worddict/* worddict.${VOC_FILE}
cp version.scw worddict.${VOC_FILE}
