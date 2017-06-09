#!/bin/bash

if [ $# != 2 ]
then
    echo "please input in file and out file"
    exit 0
fi

cat $1 | ./offline_word_splitter/bin/offline_word_splitter ./offline_word_splitter/conf/scw.conf >$2
