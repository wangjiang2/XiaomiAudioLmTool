#!/bin/bash

# loading paraments

if [ $# != 1 ] && [ $# != 2 ]; then
	echo "  Usage: $0  working_dir  [conf.sh]"
	exit 1
fi

WORKING_DIR=$1

# loading configure
source $WORKING_DIR/conf/conf.sh

echo
echo "========================================================================"
echo "worddict-build  ver.$VERSION"
echo "========================================================================"

# if local conf.sh is specified, it'll cover global conf.sh
if [ $# == 2 ]; then
	source $2
fi

# print info
if [[ $DICT == "CN" ]]; then
    echo
    echo "========================================================================"
    echo "building CN dict"
    echo "========================================================================"
    echo
    CN=1
elif [[ $DICT == "JP" ]]; then
    echo
    echo "========================================================================"
    echo "building JP dict"
    echo "========================================================================"
    echo
    JP=1
else
    echo
    echo "========================================================================"
    echo "building default dict"
    echo "========================================================================"
    echo
fi

mkdir -p bin
mkdir -p tmp/basic
mkdir -p log


#echo $CN
if [[ $CN == 1 ]]; then
    if [ ! -f ./raw_utf8/newword/newword_utf8.txt ]; then
        echo "  BUILD FAILED, raw/newword does not exist."
        exit 1
    fi
    sort -u ./raw_utf8/newword/newword_utf8.txt >./tmp/newword_uniq
    $WORKING_DIR/$BIN_DIR/$CN_DIR/buildnewword -f ./tmp/newword_uniq -p tmp/basic -o newword -n 1000000
    if [ $? -ne 0 ]; then
        echo "  BUILD FAILED, build newword dict failed"
        exit 1
    fi
    
    if [ ! -f ./raw_utf8/multiword/multiword_utf8.txt ]; then
        echo "  BUILD FAILED, raw/multiword does not exist."
        exit 1
    fi
    sort -u ./raw_utf8/multiword/multiword_utf8.txt >./tmp/multiword_uniq
    $WORKING_DIR/$BIN_DIR/$CN_DIR/buildmultiword -f ./tmp/multiword_uniq -p tmp/basic -o multi_dict -n 1000000
    if [ $? -ne 0 ]; then
        echo "  BUILD FAILED, build multiword failed 1"
        exit 1
    fi

    if [ ! -f ./raw_utf8/crf_model ]; then
        echo " BUILD FAILED, raw/crf_model does not exist."
        exit 1
    fi
    cp ./raw_utf8/crf_model ./tmp/basic
    if [ $? -ne 0 ]; then
        echo " BUILD FAILED, copy crf_model to tmp failed."
        exit 1
    fi
fi

echo
echo "========================================================================"
echo "building basic dict"
echo "========================================================================"
echo

if [ ! -d ./raw_utf8/basic ]; then
    echo "  BUILD FAILED, raw_utf8/basic does not exist."
    exit 1
fi

echo "checking basic dict"
$WORKING_DIR/$BIN_DIR/raw_check_utf8.sh raw_utf8/basic/*.basic

if [ $? -ne 0 ]; then
    echo "  BUILD FAILED, raw/basic/*.basic check failed."
    exit 1
fi

echo "cat all basic dict"
cat ./raw_utf8/basic/*.basic > ./tmp/basic.tmp
if [ $? -ne 0 ]; then
    echo "  BUILD FAILED, cat basic failed"
    exit 1
fi

$WORKING_DIR/$BIN_DIR/rmlog.pl tmp/basic.tmp > tmp/basic.tmp1
mv tmp/basic.tmp1 tmp/basic.tmp


echo "sorting basic dict"
$WORKING_DIR/$BIN_DIR/sort_dict_utf8 0 < tmp/basic.tmp > tmp/total_basic.txt
if [ $? -ne 0 ]; then
    echo "  BUILD FAILED, sort total basic failed"
    exit 1
fi

echo "building binary basic dict"

if [[ $CN == 1 ]]; then
    $WORKING_DIR/$BIN_DIR/chs_buildDict_utf8 -d tmp/total_basic.txt -a tmp/amb.basic -b tmp/basic/worddict.scw -l 1
    if [ $? -ne 0 ]; then
        echo "  BUILD FAILED, build basic dict failed"
        exit 1
    fi

    if [ ! -f ./raw_utf8/namerule/special_sname_utf8.txt ]; then
        echo "BUILD FAILED, do not exist special_sname.txt in the raw/namerule"
        exit 1
    fi
	
    if [ ! -f ./raw_utf8/namerule/leftrule_utf8.txt ]; then
        echo "BUILD FAILED, do not exist leftrule.txt in the raw/namerule"
        exit 1
    fi
	
    if [ ! -f ./raw_utf8/namerule/rightrule_utf8.txt ]; then
        echo "BUILD FAILED, do not exist rightrule.txt in the raw/namerule"
        exit 1
    fi
	
    $WORKING_DIR/$BIN_DIR/$CN_DIR/build_spec_surname < ./raw_utf8/namerule/special_sname_utf8.txt tmp/basic sname
	
    if [ $? -ne 0 ]; then
        echo "  BUILD FAILED, build_namerule failed 1"
        exit 1
    fi
	
    $WORKING_DIR/$BIN_DIR/$CN_DIR/build_namerule < ./raw_utf8/namerule/leftrule_utf8.txt tmp/basic leftrule
    if [ $? -ne 0 ]; then
        echo "  BUILD FAILED, build_namerule failed 2"
        exit 1
    fi

    $WORKING_DIR/$BIN_DIR/$CN_DIR/build_namerule < ./raw_utf8/namerule/rightrule_utf8.txt tmp/basic rightrule
    if [ $? -ne 0 ]; then
        echo "  BUILD FAILED, build_namerule failed 3"
        exit 1
    fi
elif [[ $JP == 1 ]]; then
    $WORKING_DIR/$BIN_DIR/jpn_buildDict_utf8 -d tmp/total_basic.txt -a tmp/amb.basic -b tmp/basic/worddict.scw -l 2
    if [ $? -ne 0 ]; then
        echo "  BUILD FAILED, build basic dict failed"
        exit 1
    fi
else
    $WORKING_DIR/$BIN_DIR/buildDict_utf8 -d tmp/total_basic.txt -b tmp/basic/worddict.scw -l 0
    if [ $? -ne 0 ]; then
        echo "  BUILD FAILED, build basic dict failed"
        exit 1
    fi
fi

if [ -f conf/version.basic ]; then
    cp conf/version.basic tmp/basic/version.scw
    if [ $? -ne 0 ]; then
        echo "  BUILD FAILED, cp basic version file failed"
        exit 1
    fi
fi

if [ -f conf/worddict.man ]; then
    cp conf/worddict.man tmp/basic/
    if [ $? -ne 0 ]; then
        echo "  BUILD FAILED, cp worddict.man failed"
        exit 1
    fi
fi
if [ -f conf/scw.conf ]; then
    cp conf/scw.conf tmp/basic/
    if [ $? -ne 0 ]; then
        echo "  BUILD FAILED, cp scw.conf failed"
        exit 1
    fi
fi

echo
echo "========================================================================"
echo "building phrase"
echo "========================================================================"
echo

if [ ! -d ./raw_utf8/phrase ]; then
    echo "  BUILD FAILED, raw/phrase does not exist."
    exit 1
fi

echo "cat all phrase dict"

# cat all the phrase files together
cat ./raw_utf8/phrase/*.phrase > ./tmp/phrase.tmp

if [ $? -ne 0 ]; then
    echo "  BUILD FAILED, cat phrase failed"
    exit 1
fi

$WORKING_DIR/$BIN_DIR/rmlog.pl ./tmp/phrase.tmp > ./tmp/phrase.tmp1
mv ./tmp/phrase.tmp1 ./tmp/phrase.tmp


echo "sorting phrase dict"
$WORKING_DIR/$BIN_DIR/sort_dict_utf8 1 < tmp/phrase.tmp > tmp/phrase.tmp2
if [ $? -ne 0 ]; then
	echo "  BUILD FAILED, sort phrase failed"
	exit 1
fi

echo "building phrase info using binary basic dict"
if [ ! -f ./raw_utf8/other/place_suffix_utf8.txt ]; then
    echo "BUILD WARNING, do not exist place_suffix.txt in the raw/other"
fi

# seg phrase and build subphrase
$WORKING_DIR/$BIN_DIR/build_phrase_utf8 tmp/basic/ raw_utf8/other/place_suffix_utf8.txt tmp/phrase.tmp1 < tmp/phrase.tmp2 > tmp/phrase.tmp3 
if [ $? -ne 0 ]; then
    echo "  BUILD FAILED, build phrase failed"
    exit 1
fi

echo "sorting phrase dict"
sort < tmp/phrase.tmp1 | uniq > tmp/phrase.tmp5

$WORKING_DIR/$BIN_DIR/sort_dict_utf8 0 < tmp/phrase.tmp5 > tmp/total_dynword.txt
if [ $? -ne 0 ]; then
    echo "  BUILD FAILED, sort phrase dict failed"
    exit 1
fi

echo "merging pre-defined phrase dict"
if [[ $CN == 1 ]]; then
    # merge disambiguation.txt and handadjust.txt	
    if [ ! -f ./raw_utf8/other/qypd_utf8.txt ]; then
        echo "BUILD FAILED, do not exist qypd.txt in the raw/other"
        exit 1
    fi
    if [ ! -f ./raw_utf8/other/handwork_utf8.txt ]; then
        echo "BUILD FAILED, do not exist handwork.txt in the raw/other"
        exit 1
    fi

    $WORKING_DIR/$BIN_DIR/$CN_DIR/merge_spec_phrase raw_utf8/other/qypd_utf8.txt raw_utf8/other/handwork_utf8.txt < tmp/phrase.tmp3 > tmp/phrase.tmp4
    if [ $? -ne 0 ]; then
        echo "  BUILD FAILED, merge_spec_phrase failed"
        exit 1
    fi
    
    #merge qfphrase.txt
    if [ -f ./raw_utf8/other/qfphrase_utf8.txt ]; then
        cat tmp/phrase.tmp4 ./raw_utf8/other/qfphrase_utf8.txt > tmp/phrase.tmp6
    else
        mv tmp/phrase.tmp4 tmp/phrase.tmp6
    fi
else	
    #merge qfphrase.txt
    if [ -f ./raw_utf8/other/qfphrase_utf8.txt ]; then
        cat tmp/phrase.tmp3 ./raw_utf8/other/qfphrase_utf8.txt > tmp/phrase.tmp6
    else
        mv tmp/phrase.tmp3 tmp/phrase.tmp6
    fi
fi
mv tmp/phrase.tmp6 tmp/phrase.tmp4

echo "sorting phrase dict"
$WORKING_DIR/$BIN_DIR/sort_dict_utf8 0 < tmp/phrase.tmp4 > tmp/total_phrase.txt
if [ $? -ne 0 ]; then
    echo "  BUILD FAILED, sort all phrase dict failed"
    exit 1
fi
if [[ $JP == 1 ]]; then
    #echo "checking phrase dict"
    $WORKING_DIR/$BIN_DIR/raw_check_utf8.sh tmp/total_phrase.txt tmp/total_dynword.txt
    if [ $? -ne 0 ]; then
        echo "  BUILD FAILED, total_phrase/dynword check failed."
        exit 1
    fi
fi

echo
echo "========================================================================"
echo "building total dict"
echo "========================================================================"
echo

echo "cat all dict"
cat tmp/total_basic.txt tmp/total_phrase.txt tmp/total_dynword.txt > tmp/total.tmp
if [ $? -ne 0 ]; then
    echo "  BUILD FAILED, join basic and phrase failed"
    exit 1
fi

if [[ $JP == 1 ]]; then
    echo "(only in JP) check jp prop"
    # check if katakana correctly add -F prop
    $WORKING_DIR/$BIN_DIR/$JP_DIR/check_jp < tmp/total.tmp > tmp/total.tmp1
    mv tmp/total.tmp1 tmp/total.tmp
fi

echo "sorting all dict"
$WORKING_DIR/$BIN_DIR/sort_dict_utf8 0 < tmp/total.tmp > tmp/total.tmp1
if [ $? -ne 0 ]; then
    echo "  BUILD FAILED, sort all dict failed"
    exit 1
fi

echo "checking dismatch in all dict, result storing in tmp/phrase.err"
$WORKING_DIR/$BIN_DIR/check.pl tmp/total.tmp1 tmp/phrase.err | $WORKING_DIR/$BIN_DIR/sort_dict_utf8 0 > tmp/total_raw.txt

if [[ $JP == 1 ]]; then
    #echo "checking all dict"
    $WORKING_DIR/$BIN_DIR/raw_check_utf8.sh tmp/total_raw.txt
    if [ $? -ne 0 ]; then
        echo "  BUILD FAILED, total_raw check failed."
        exit 1
    fi
fi


echo "building binary total dict"
if [[ $CN == 1 ]]; then
    $WORKING_DIR/$BIN_DIR/chs_buildDict_utf8 -d tmp/total_raw.txt -a tmp/amb.tmp2 -p raw_utf8/property/property_ex_utf8.txt -h raw_utf8/namedata/cnameprob_utf8.txt -f raw_utf8/namedata/fnameprob_utf8.txt -b bin/worddict.scw -l 1
    if [ $? -ne 0 ]; then
        echo "  BUILD FAILED, build_dict failed"
        exit 1
    fi

    $WORKING_DIR/$BIN_DIR/$CN_DIR/build_spec_surname < raw_utf8/namerule/special_sname_utf8.txt bin/ sname
    if [ $? -ne 0 ]; then
        echo "  BUILD FAILED, build_spec_surname failed"
        exit 1
    fi

    $WORKING_DIR/$BIN_DIR/$CN_DIR/build_namerule < raw_utf8/namerule/leftrule_utf8.txt bin/ leftrule
    if [ $? -ne 0 ]; then
        echo "  BUILD FAILED, build_namerule - leftrule failed"
        exit 1
    fi
	
    $WORKING_DIR/$BIN_DIR/$CN_DIR/build_namerule < raw_utf8/namerule/rightrule_utf8.txt bin/ rightrule
    if [ $? -ne 0 ]; then
        echo "  BUILD FAILED, build_namerule - rightrule failed"
        exit 1
    fi
    
    cp ./tmp/basic/crf_model bin/
    if [ $? -ne 0 ]; then
        echo " BUILD FAILED, copy crf_model to bin failed."
        exit 1
    fi
    cp ./tmp/basic/multi_dict bin/
    if [ $? -ne 0 ]; then
        echo " BUILD FAILED, copy multi_dict to bin failed."
        exit 1
    fi
    cp ./tmp/basic/newword.* bin/
    if [ $? -ne 0 ]; then
        echo " BUILD FAILED, copy newworddict to bin failed."
        exit 1
    fi
elif [[ $JP == 1 ]]; then
    $WORKING_DIR/$BIN_DIR/jpn_buildDict_utf8 -d tmp/total_raw.txt -a tmp/amb.tmp2 -p raw_utf8/property/property_ex_utf8.txt -h raw_utf8/namedata/nameprob_utf8.txt -b bin/worddict.scw -l 2
    if [ $? -ne 0 ]; then
        echo "  BUILD FAILED, build_dict failed"
        exit 1
    fi
    $WORKING_DIR/$BIN_DIR/$JP_DIR/build_goi_dict bin/ goi < raw/other/term.py
    if [ $? -ne 0 ]; then
        echo "  BUILD FAILED, build_goi_dict failed"
        exit 1
    fi
else
    $WORKING_DIR/$BIN_DIR/buildDict_utf8 -d tmp/total_raw.txt -b bin/worddict.scw -l 0
    if [ $? -ne 0 ]; then
        echo "  BUILD FAILED, build_dict failed"
        exit 1
    fi
fi

if [ -f conf/version.scw ]; then
    cp conf/version.scw bin/
fi

if [ -f conf/worddict.man ]; then
    cp conf/worddict.man bin/
fi

if [ $? -ne 0 ]; then
    echo "  BUILD FAILED, cp worddict.man failed"
    exit 1
fi

echo "md5sum dict"

#get md5 value

md5sum ./bin/* > bin/worddict.md5 

echo "copying to worddict"
if [ -d worddict ]; then
    rm -rf worddict
fi

cp -r ./bin/ ./worddict 
rm -rf ./worddict/CVS/

echo
echo "========================================================================"
echo "dict has been successfully built"
echo "========================================================================"
