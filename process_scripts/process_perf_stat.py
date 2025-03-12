#!/bin/python3

import os,sys,locale
import subprocess

def get_lines_grep(filename,event,mode,tid):
    cat_cmd = "cat "+filename
    process = subprocess.Popen(cat_cmd.split(), stdout=subprocess.PIPE)
    out1 = subprocess.Popen(('grep', event+':'+mode), stdin=process.stdout, stdout=subprocess.PIPE)
    #out2 = subprocess.Popen(('grep', tid), stdin=out1.stdout, stdout=subprocess.PIPE)
    output = subprocess.check_output(('grep', tid), stdin=out1.stdout)
    #output = subprocess.check_output(('wc', '-l'), stdin=out2.stdout)
    output = str(output).split('\'')[1].split("\\n")[:-1]
    #print(output, end="")
    return output

def get_lines_read(filename, event, mode, tid):
    fp = open(filename, 'r+')
    lines = fp.readlines()
    get_lines = []
    for line in line:
        if event+':'+mode in line and tid in line:
            get_lines.append(line)
    return get_lines


pid_list = []
for pids in sys.stdin:
    pid_list += pids[:-1].split(',')

print(pid_list)

events = ["cycles","instructions"]
modes = ["u","k"]

tid_cmd = "ps -T -o spid "

for pid in pid_list:
    cmd = tid_cmd+pid
    process = subprocess.Popen(cmd.split(), stdout=subprocess.PIPE)
    tid_list, error = process.communicate()
    tid_list = str(tid_list).split('\'')[1].split("\\n")[1:-1]
    tid_list = [x.split()[0] for x in tid_list]
    #print(tid_list)
    for tid in tid_list:
        for event in events:
            for mode in modes:
                lines = get_lines_read("../cycle_inst_stat",event,mode,tid)
                for line in lines:
                    line = line.replace("<not counted>","0")
                    segments = line.split()
                    time


