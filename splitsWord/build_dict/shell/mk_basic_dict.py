#/usr/bin/env python

import os
import sys

args = sys.argv
if len(args) != 3:
    print('usage: mk_basic_dict infile outfile')
    sys.exit(0)

outfile = open(args[2], 'w')

infile = open(args[1], 'r')
for line in infile:
    line = line.strip()
    outfile.write('[' + line  + '] [0(' + line + ')] [] - 1000\n')

infile.close()
outfile.close()
