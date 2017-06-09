#!/bin/bash

if [ $# != 1 ]
then
    echo "please input dictionary"
    exit 0
fi

./shell/get_worddict.sh $1
