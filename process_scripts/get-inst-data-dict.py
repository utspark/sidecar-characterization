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
        ("accept",".] Envoy::Server::ActiveTcpListener::onAcceptWorker$"),
        ("rbac",".] Envoy::Extensions::NetworkFilters::.*onData$")
        ]

def save(total, val, func, data):
    raw_val = val*total/100
    if func in data.keys():
        data[func]['pct'].append(val)
        data[func]['abs'].append(raw_val)
    else:
        data.update({func:{'pct':[val],'abs':[raw_val]}})
    if "total" not in data.keys():
        data.update({"total":{'pct':[total],'abs':[total]}})
    elif func == "read":
        data["total"]['pct'].append(total)
        data["total"]['abs'].append(total)
    return data

output_dir=sys.argv[1]
pwd= os.getcwd()
os.chdir(output_dir)
dirs = [d for d in os.listdir(".") if os.path.isdir(d)]
all_data = {}
for directory in dirs:
    os.chdir(directory)
    perf_rec = glob.glob('instructions_record_x*')
    data = {}
    for rec in perf_rec:
        if 'old' in rec:
            continue
        #met_ = rec[:-9].split(',')
        fp=open("perf_report_"+rec,'r')
        lines = fp.readlines()
        for c,f in fun:
            arrval=0
            total=0
            for line in lines:
                regex=re.compile(f)
                if regex.search(line):
                    #print(line)
                    linearray = line.split()
                    arrval += float(linearray[0][:-1])
                elif 'approx' in line:
                    linearray = line.split()
                    total = int(linearray[-1])
            data = save(total,arrval,c,data)
    all_data.update({directory:data})
    os.chdir("..")

os.chdir(pwd)
with open('perf_inst_1req_1k.pkl', 'wb') as handle:
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

