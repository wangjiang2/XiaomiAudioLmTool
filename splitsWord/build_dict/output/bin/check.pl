#!/usr/bin/perl -w

###########################################################################
#                                                                         #
#                               David Dai                                 #
#                         Copyright (c) 2007                              #
#                        All Rights Reserved.                             #
#                                                                         #
#  Permission is hereby granted, free of charge, to use and distribute    #
#  this software and its documentation without restriction, including     #
#  without limitation the rights to use, copy, modify, merge, publish,    #
#  distribute, sublicense, and/or sell copies of this work, and to        #
#  permit persons to whom this work is furnished to do so, subject to     #
#  the following conditions:                                              #
#   1. The code must retain the above copyright notice, this list of      #
#      conditions and the following disclaimer.                           #
#   2. Any modifications must be clearly marked as such.                  #
#   3. Original authors' names are not deleted.                           #
#   4. The authors' names are not used to endorse or promote products     #
#      derived from this software without specific prior written          #
#      permission.                                                        #
#                                                                         #
#  DAVID DAI AND THE CONTRIBUTORS TO THIS WORK DISCLAIM ALL WARRANTIES    #
#  WITH REGARD TO THIS SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF      #
#  MERCHANTABILITY AND FITNESS, IN NO EVENT SHALL NETEASE NOR THE         #
#  CONTRIBUTORS BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL      #
#  DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA     #
#  OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER      #
#  TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR       #
#  PERFORMANCE OF THIS SOFTWARE.                                          #
#                                                                         #
###########################################################################
#                                                                         #
# ������շִ��ı��ʵ������ݵ�һ���ԣ�                                    #
# 1. �������з�Ƭ���Ƿ�Ϊ�����ʡ�                                     #
# ����: total_raw.txt                                                     #
# ���: ��Ļ�������һ�½������phrase.err�ļ���                          #
# Author: David Dai (daishuaixiang@baidu.com)                             #
#									  #
# mod by: Hejingzhou (Hejingzhou@baidu.com)				  #
# ���ڼ�������phrase���Զ����������					  # 
#                                                                         #
###########################################################################


$USAGE = "Usage:\t$0 totalfile error_report\n";	
if (@ARGV < 2) { print "$USAGE\n"; exit; }

my %phr_dict = ();

## read all phrases
open(PHRERR, ">$ARGV[1]");
open(TOTAL, $ARGV[0]) || die "$ARGV[0]: $!\n"; 
while($line = <TOTAL>) 
{
	next if $line eq "\n"; 
  my $pattern = "[ \\t\\r\\n\\f]+";
  my @cols = split(/$pattern/, $line);
  
  if( @cols == 5 )
  {
	#print STDOUT "$cols[0] $cols[1] $cols[2] $cols[3] $cols[4]\n";
    if( index($cols[3],"-P") != -1 ) ## only handle phrase
    {
	if( $cols[1]=~/\(.+\).+\(.+\)/ )
	{
		$phr_dict{$cols[0]} = "$cols[1] $cols[2] $cols[3] $cols[4]";
		next;
	}
	else
	{
		print PHRERR "phrase should be basic (deleted -P): $line";
	# ����ӦΪbasic��phrase
	$cols[3]=~s/-P//;
	$cols[3]="-" if($cols[3] eq "");
	$line="$cols[0] $cols[1] $cols[2] $cols[3] $cols[4]\n";
	}
    }
  }
	print STDOUT $line;
}
close(TOTAL);

## check each phrase and print result
open(TOTAL, $ARGV[0]) || die "$ARGV[0]: $!\n"; 
while($line = <TOTAL>) 
{          
	next if $line eq "\n";
  my $pattern = "[ \\t\\r\\n\\f]+";
  my @cols = split(/$pattern/, $line);
	my @basiclist=();
  
  my $good = 1;
  
  if( @cols == 5 )
  {
    if( index($cols[3],"-P") != -1 ) ## only handle phrase
    {
      $text = $cols[1];
	$text=~s/\[(.+?)\]/$1/;
      $pat = "[\(\)]";
      @terms = split(/$pat/,$text);
      
      if( @terms >= 4 )
      {
	# �������Ϊphrase��basic�зֵ�Ԫ
        # ����phrase��basic�з���Ϣ�滻ԭ����basic�зֵ�Ԫ
        # ���磺
        #       [remix] [(0)re(1)mix]
        #       [remix��] [(0)remix(1)��]
        # �����Ժ󽫱�ɣ�
        #       [remix��] [(0)re(1)mix(2)��]
      	for( $i=1; $i<@terms; $i+=2 )
        {
                # �������Ϊphrase��basic�зֵ�Ԫ
                # ����phrase��basic�з���Ϣ�滻ԭ����basic�зֵ�Ԫ
                # ���磺
                #       [remix] [(0)re(1)mix]
                #       [remix��] [(0)remix(1)��]
                # �����Ժ󽫱�ɣ�
                #       [remix��] [(0)re(1)mix(2)��]
      	  if( exists $phr_dict{"[".$terms[$i]."]"} )
      	  {
		# ������phrase��-Z����ȥ��
		$phr_dict{"[".$terms[$i]."]"}=~s/-Z//g;

		$phr_dict{"[".$terms[$i]."]"}=~/^(.+?) /;
		$basic=$1;
		$basic=~s/\[(.+?)\]/$1/;
		@basics = split(/$pat/,$basic);
		$terms[$i]="";
		for( $j=1; $j<@basics; $j+=2 )
		{
			push @basiclist,"$basics[$j]";
		}
      	    $good = 0;
      	  }
		else
		{
			push @basiclist,"$terms[$i]";
		}
        }

	# �����滻���Ĵ�������������basic�з���Ϣ��subphrase��Ϣ
	if( $good == 0 )
	{
		$newbasicseg="";
		$newsubpseg="";
		for( $i=0; $i<@basiclist; $i++ )
		{
			next if $basiclist[$i] eq "";
			$newbasicseg.="$i($basiclist[$i])";
			$tempsubp="$basiclist[$i]";
			for( $j=$i+1; $j<@basiclist; $j++ )
			{
				$tempsubp.=$basiclist[$j];
				$newsubpseg.="$i($tempsubp)" if ( exists $phr_dict{"[$tempsubp]"} ) and "[$tempsubp]" ne $cols[0];
			}
		}
		print PHRERR "<$line---\n>$cols[0] [$newbasicseg] [$newsubpseg] $cols[3] $cols[4]\n\n";
		$phr_dict{"$cols[0]"}="[$newbasicseg] [$newsubpseg] $cols[3] $cols[4]";
		#print STDOUT "$cols[0] [$newbasicseg] [$newsubpseg] $cols[3] $cols[4]\n";
	}
      }
    }
  }   
  
##  if( $good )
##  {
##   print("$line");
## }
}
close(PHRERR);
close(TOTAL);

foreach (keys %phr_dict)
{
	print STDOUT "$_ $phr_dict{$_}\n";
}

exit(0);

