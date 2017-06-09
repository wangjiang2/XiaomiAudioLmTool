#!/bin/bash


export LC_ALL=zh_CN.utf8

if [ $# == 0 ]; then
    echo "Usage: $0 [file list]"
    exit 1
fi

HAS_ERROR=0
for file in $*
do
    if [ ! -f $file ]; then
        continue
    fi
    awk -v flag=0 '
    {
        delete hash;

        if( NF!=5 )
        {
            print "Error in "FILENAME" (field number != 5): "$0;
	    flag=1;
	    next;
	}

        if( length($1)<3 || length($2)<5 || length($3)<2 )
        {
            print "Error in "FILENAME" (field format error): "$0;
            flag=1;
            next;
        }

        if( $5!~/[0-9]+/ )
        {
            print "Error in "FILENAME" (weight error): "$0;
            flag=1;
            next;
        }
		
        split($4,proplist,"-");
        for (key in proplist)
        {
            if( proplist[key]=="" ) 
                continue;
            if( hash[proplist[key]]==1 )
            {
                print "Error in "FILENAME" (prop field error): "$0;
                flag=1;
                next;
            }
            else
            {
                hash[proplist[key]]=1;
            }
        }
		
        word=substr($1,2,length($1)-2);
        basic=substr($2,2,length($2)-2);
        subph=substr($3,2,length($3)-2);
		
        if( $1!~/^\[.+\]$/ )
        {
            print "Error in "FILENAME" (word content error): "$0;
            flag=1;
	    next;
        }

        if( basic!~/([0-9]+\(.+\))+/ )
        {
            print "Error in "FILENAME" (basic field format error): "$0;
            flag=1;
            next;
        }
		
        sub(/^0\(/,"",basic);
        sub(/\)$/,"",basic);
        gsub(/\)[0-9]+\(/,"",basic);

	if( basic != word )
        {
            print "Error in "FILENAME" (basic dismatch): "word,basic;
            flag=1;
            next;
        }
		
        if( subph != "" )
        {
            if( subph!~/([0-9]+\(.+\))+/ )
            {
                print "Error in "FILENAME" (subph field format error): "$0;
                flag=1;
                next;
            }
            sub(/^[0-9]+\(/,"",subph);
            sub(/\)$/,"",subph);
            split(subph,sublist,/\)[0-9]+\(/);
            for (key in sublist)
            {
                found=0;
                for(i=1;i<=length(word)-length(sublist[key])+1;i++)
                {
                    if( substr(word,i,length(sublist[key]))==sublist[key] )
                    {
                        found=1;
                        break;
                    }
                }
                if( found==0 )
                {
                    print "Error in "FILENAME" (subph dismatch): "sublist[key],word;
                    flag=1;
                    next;
                }
            }
        }
    }
    END{
        if(flag==1)
            exit 1;
        else 
            exit 0;
    }
    ' $file
	
    if [ $? == 1 ]; then
        HAS_ERROR=1
    fi
done

if [ $HAS_ERROR == 1 ]; then
    exit 1
fi
