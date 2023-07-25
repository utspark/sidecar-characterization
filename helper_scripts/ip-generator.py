#!/bin/python3

i1 = '10'
i2 = '20'
i3 = 0
i4 = 0
lim = '.'

for x in range(100):
    for y in range(100):
        ip = i1+lim+i2+lim+str(x)+lim+str(y)
        print('                  - source_ip:')
        print('                      address_prefix: '+ip)
        print('                      prefix_len: 32')
