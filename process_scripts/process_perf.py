#!/bin/python3

import os,sys,locale
import numpy as np
from operator import add
locale.setlocale(locale.LC_ALL, 'en_US.UTF-8')

def avg(lst):
    return sum(lst)/len(lst)

fname = sys.argv[1]
fp = open(fname)

c = 'cycles'
i = 'inst'
u = 'u'
k = 'k'
data = {c : {u:[],k:[]}, i : {u:[],k:[]}}
for l in fp.readlines():
    v=l.split()
    if i in l:
        if ':u' in l:
            data[i][u].append(locale.atoi(v[1]))
        if ':k' in l:
            data[i][k].append(locale.atoi(v[1]))
    if c in l:
        if ':u' in l:
            data[c][u].append(locale.atoi(v[1]))
        if ':k' in l:
            data[c][k].append(locale.atoi(v[1]))

print(np.percentile(data[c][u],90))
print(np.percentile(data[c][k],90))
print(np.percentile(list(map(add,data[c][k],data[c][u])),90))
print(avg(data[i][u]))
print(avg(data[i][k]))
