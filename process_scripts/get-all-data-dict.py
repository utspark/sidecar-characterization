#!/bin/python
import os,sys
import subprocess
import glob
import fnmatch
import re
import pickle

fun = [
        ("read",".] Envoy::Network::ConnectionImpl::onReadReady$"),
        ("write",".] Envoy::Network::ConnectionImpl::onWriteReady$"),
        ("tcp",".] Envoy::TcpProxy::Filter::.*Data$"),
        ("http",".] Envoy::Http::Http1::ConnectionImpl::dispatch$"),
        ("header",".] Envoy::Http::FilterManager::decodeHeaders$"),
        ("filter",".] Envoy::Extensions::HttpFilters::.*decodeHeaders$"),
        ("epoll",".] epoll_wait$"),
        ("log",".] Envoy::Http::FilterManager::log$"),
        ("readv","k] do_readv$"),
        ("writev","k] do_writev$"),
        ("rbac",".] Envoy::Extensions::NetworkFilters::.*onData$")
        ]

def save(total, val, func, metric, data):
    if metric in data.keys():
        if func in data[metric].keys():
            data[metric][func].append(val)
        else:
            if metric == "instructions":
                data[metric].update({func:[val]})
            else:
                data[metric].update({func:val})
    else:
        if metric == "instructions":
            data.update({metric:{func:[val]}})
        else:
            data.update({metric:{func:val}})
    if metric == "instructions":
        if "total" not in data[metric].keys():
            data[metric].update({"total":[total]})
        elif func == "read":
            data[metric]["total"].append(total)
    else:
        if "total" not in data[metric].keys():
            data[metric].update({"total":total})
    return data


output_dir=sys.argv[1]
pwd= os.getcwd()
os.chdir(output_dir)
dirs = [d for d in os.listdir(".") if os.path.isdir(d)]
all_data = {}
for directory in dirs:
    #if 'mix' not in directory:
    #    continue
    os.chdir(directory)
    perf_rec = glob.glob('instructions*_record-*')
    data = {}
    for rec in perf_rec:
        met_ = rec[:-9].split(',')
        fp=open("perf_report_"+rec,'r')
        lines = fp.readlines()
        for c,f in fun:
            arrval=0
            metc=-1
            total=0
            for line in lines:
                regex=re.compile(f)
                if regex.search(line):
                    linearray = line.split()
                    arrval += float(linearray[0][:-1])
                elif 'approx' in line:
                    if metc >= 0:
                        data = save(total,arrval,c,met_[metc],data)
                    linearray = line.split()
                    metc+=1
                    arrval=0
                    total = int(linearray[-1])
            if metc >= 0:
                data = save(total,arrval,c,met_[metc],data)
    all_data.update({directory:data})
    os.chdir("..")

os.chdir(pwd)
with open('perf_all_stats_0724.pkl', 'wb') as handle:
    pickle.dump(all_data, handle)

#print(all_data)
#print(all_met)
#for directory in dirs:
#    print(directory, end="")
#    m = "instructions"
#    for j,fn in enumerate(fun):
#        f = fn[0]
#        inst_data = [float(i) for i in all_data[directory][m][f]]
#        print(",,,"+str(all_data[directory][m][f])[1:-1]+','+str(sum(inst_data)/len(inst_data)), end="") 
#    print("")
#for directory in dirs:
#    print(directory, end="")
#    for m in all_met:
#        if m == "instructions":
#            continue
#        for j,fn in enumerate(fun):
#            f = fn[0]
#            print(","+str(all_data[directory][m][f]), end="") 
#        print(",", end="")
#    print("")

