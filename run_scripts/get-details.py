#!/bin/python3

import subprocess
import pickle
import json
import sys
import argparse

cpidCmd = "ps --ppid <PID> -o pid "
tidCmd = "ps -T -o spid "     # add pid after command

def checkname(name):
    if 'kube-' in name or 'calico' in name or 'dns' in name or 'etcd' in name or 'metrics' in name:
        return 'kube'
    elif 'proxy' in name or 'envoy' in name:
        return 'sidecar'
    elif 'pilot' in name:
        return 'istio'
    elif 'pause' in name:
        return 'pause'
    else:
        return 'app'

def get_ids(command, pid):
    if pid == None:
        return []
    process = subprocess.Popen(command.split(), stdout=subprocess.PIPE)
    id_list, error = process.communicate()
    id_list = str(id_list).split('\'')[1].split("\\n")[1:-1]
    id_list = [x.split()[0] for x in id_list]
    return id_list

def get_pid(cat, data, write):
    pids = []
    if cat == "all":
        pid_kube = get_pid("kube",data,False)
        pid_istio = get_pid("istio",data,False)
        pid_sidecar = get_pid("sidecar",data,False)
        pid_app = get_pid("app",data,False)
        pids = pid_kube+pid_istio+pid_sidecar+pid_app
    else:
        for cgroup in data:
            for ctr in data[cgroup]:
                if checkname(data[cgroup][ctr]["name"]) == cat:
                    pids.append(data[cgroup][ctr]["pid"])
        if cat == "sidecar" or cat == "istio":
            new_pids = []
            for pid in pids:
                new_pids += get_ids(cpidCmd.replace("<PID",pid),pid)
            pids += new_pids
    if write == True:
        print(','.join(pids))
    return pids

def get_ctr_info():
    ctrdContainers = "sudo ctr --namespace k8s.io containers ls"
    ctrdTasks = "sudo ctr --namespace k8s.io tasks ls"
    
    process = subprocess.Popen(ctrdContainers.split(), stdout=subprocess.PIPE)
    container_list, error = process.communicate()
    container_list = str(container_list).split('\'')[1].split("\\n")
    process = subprocess.Popen(ctrdTasks.split(), stdout=subprocess.PIPE)
    task_list, error = process.communicate()
    task_list = str(task_list).split('\'')[1].split("\\n")
    
    containers = {}
    details = {}
    
    for task in task_list[1:-1]:
        temp = task.split()
        cid = temp[0]
        pid = temp[1]
        cpid_list = get_ids(cpidCmd.replace("<PID>", pid),pid)
        if len(cpid_list) > 1:
            print("something to check with PID"+pid+". Has cpid="+str(cpid_list))
        if len(cpid_list) == 0:
            cpid = None
        else:
            cpid = cpid_list[0]
        children = {}
        for cpid in cpid_list:
            ctid = get_ids(tidCmd+cpid, cpid)
            children[cpid] = ctid

        #containers[cid] = {'pid': pid, 'cpid': cpid, 'tid': get_ids(tidCmd+pid, pid), 'ctid': get_ids(tidCmd+str(cpid), cpid)}
        containers[cid] = {'pid': pid, 'tid': get_ids(tidCmd+pid, pid), 'cpid': children}
    
    for ctr in container_list[1:-1]:
        temp = ctr.split()
        cid = temp[0]
        name = temp[1]
        if cid in containers:
            attr = containers.get(cid)
            containers[cid].update({'name': name})
    
    for cid in containers:
        pid = containers[cid]['pid']
        cmd = "cat /proc/"+pid+"/cgroup"
        process = subprocess.Popen(cmd.split(), stdout=subprocess.PIPE)
        cgroup_list, error = process.communicate()
        cgroup_list = str(cgroup_list).split('\'')[1].split("\\n")
        cgroup = cgroup_list[0].split(":")[2]

        if cgroup in details.keys():
            details[cgroup].update({cid:containers[cid]})
        else:
            details[cgroup] = {cid:containers[cid]}
    return details

parser = argparse.ArgumentParser()
parser.add_argument("-t", "--type", type=str, choices=["kube", "istio", "app", "sidecar","pause","all"],
                            help="display all pids of given type")
parser.add_argument("-d", "--dump", type=str, choices=["pickle", "json"],
                            help="increase output verbosity")
args = parser.parse_args()

details = get_ctr_info()

if args.dump == 'pickle':
    with open('saved_dictionary.pkl', 'wb') as f:
        pickle.dump(details, f)
    print(details)
elif args.dump == 'json':
    json_obj = json.dumps(details, indent = 2)
    print(json_obj)

if args.type != None:
    get_pid(args.type, details, True)
