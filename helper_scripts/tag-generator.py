#!/bin/python3

i1 = '10'
i2 = '20'
i3 = 0
i4 = 0
lim = '.'

for x in range(3):
    for y in range(3):
        ip = str(x*100+y)
        print('              - ip_tag_name: tagged_by_envoy_'+ip)
        print('                ip_list:')
        print('                - address_prefix: 0.0.0.0')
