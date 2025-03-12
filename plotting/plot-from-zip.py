import zipfile
import pandas as pd
import os
import csv
import matplotlib.pyplot as plt
import helper
import numpy as np
import sys

def is_number(s):
    try:
        float(s)
        return True
    except ValueError:
        return False

if len(sys.argv) < 2:
    print("Usage: python plot-from-zip.py source_dir [destination_dir]")
    sys.exit(1)

zip_path = sys.argv[1]

if len(sys.argv) == 2:
    unzip_path = os.path.join(os.getcwd(), 'exp')
else:
    unzip_path = sys.argv[2]

# Expected ZIP structure:
# cpu_num_rate.zip
# ├── l4
# │   ├── stat
# │   │   ├── header_inspect
# │   │   │   ├── <rate>_<metric>.csv
# │   │   │   ├── e.g. 3000_mpki.csv
# │   │   │   ├── ... (CSV files for 3 different rates, and 6 metrics -  [no prefix], branch, icache, ipmispredict, llc, mpki)
# │   │   ├── http_inspect
# │   │   ├── ip_filter
# │   │   ├── ip_tagging
# │   │   ├── logging (gets deleted)
# │   │   ├── no_filter
# │   │   ├── rate_limit
# │   │   ├── rbac_list
# │   │   ├── rbac_one
# │   │   ├── routing
# ├── l7
# │   ├── stat
# │   │   ├── header_inspect
# │   │   ├── ...

NUM_CPUS = 1 # fix

# Renames the filenames for these folders to account for two worker threads working
# at the same request rate. 
def fix_routing_and_header_inspect_rates(source_dir):
    for subdir, dirs, files in os.walk(source_dir):
        for dir in dirs:
            if 'header_inspect' in dir or 'routing' in dir:
                dir_path = os.path.join(subdir, dir)
                for filename in os.listdir(dir_path):
                    old_path = os.path.join(subdir, dir, filename)
                    new_filename = filename
                    if '3000' in new_filename:
                        new_filename = new_filename.replace('3000', '6000')
                    new_path = os.path.join(subdir, dir, new_filename)
                    os.rename(old_path, new_path)
                for filename in os.listdir(dir_path):
                    old_path = os.path.join(subdir, dir, filename)
                    new_filename = filename
                    if '4500' in new_filename:
                        new_filename = new_filename.replace('4500', '9000')
                    if '1500' in new_filename:
                        new_filename = new_filename.replace('1500', '3000')
                    new_path = os.path.join(subdir, dir, new_filename)
                    os.rename(old_path, new_path)

def prep_data():
    with zipfile.ZipFile(zip_path, "r") as zip_file:
        zip_file.extractall(path=unzip_path)

    # Remove empty folders.
    # All experiments' folders are in both L4 and L7. 
    # This removes the duplicate experiments
    # not related to either L4/L7.
    folders = list(os.walk(unzip_path))[1:]
    for folder in folders:
        if not folder[2] and not folder[1]: # empty folder
            os.rmdir(folder[0])
        if folder[0] == 'logging': #logging folder only has .txt files
            os.rmdir(folder[0])

    # Rename header_inspect and routing files so rate accounts for 
    # two worker threads used for these experiments
    fix_routing_and_header_inspect_rates(unzip_path)

# Plot MPKI
def plot_mpkis():
    mpkis = {} # dictionary -- <rate>_<policy> : average MPKI
    for path, subdirs, files in os.walk(unzip_path):
        for name in files:
            if name.find('mpki') != -1 and name.find('csv') != -1: #found mpki file
                running_sum = count = 0
                with open(os.path.join(path, name), 'r') as f:
                    next(f) # skip first two rows
                    next(f)
                    reader = csv.reader(f, delimiter=',')
                    for row in reader:
                        if len(row) > 6 and is_number(row[6]): # found mpki value
                            running_sum += float(row[6])
                            count += 1
                    average_mpki = running_sum / count
                    # create key: <policy> <rate> i.e. rbac 1500
                    rate, metric = name.split("_")
                    policy = os.path.basename(path.rstrip("/"))
                    key = f"{policy} ({rate})"
                    mpkis[key] = average_mpki
    #print(mpkis)
    helper.plot_9_experiments(mpkis, "L1 Misses per 1000 Instructions", "L1MPKI")

# Plot IP Mispredicts
def plot_ipmispredicts():
    ipmispreds = {} # dictionary -- <rate>_<policy> : average IpMispredict
    for path, subdirs, files in os.walk(unzip_path):
        for name in files:
            if name.find('ipmispredict') != -1 and name.find('csv') != -1:
                running_sum = count = 0
                #print(name)
                with open(os.path.join(path, name), 'r') as f:
                    next(f)
                    next(f)
                    reader = csv.reader(f, delimiter=',')
                    for row in reader:
                        if len(row) > 6 and is_number(row[6]):
                            running_sum += float(row[6])
                            count += 1
                    average_ipmispred = running_sum / count
                    rate, metric = name.split("_")
                    policy = os.path.basename(path.rstrip("/"))
                    key = f"{policy} ({rate})"
                    ipmispreds[key] = average_ipmispred
    #print(ipmispreds)
    helper.plot_9_experiments(ipmispreds, "IP Mispredict Count", "IPMispredicts")

# Plot Cycles and Instructions (User and Kernel)
def plot_cycles_instrs():
    cycles_u = {} # dictionary -- <rate>_<policy> : average cycles / user
    cycles_k = {} # dictionary -- <rate>_<policy> : average cycles / kernel
    instructions_u = {} #      -- <rate>_<policy> : average instructions / user
    instructions_k = {} #      -- <rate>_<policy> : average instructions / kernel  
    for path, subdirs, files in os.walk(unzip_path):
        for name in files:
            if len(name) < 9 and name.find('csv') != -1:
                sum_c_u = sum_c_k = sum_i_u = sum_i_k = count = 0
                with open(os.path.join(path, name), 'r') as f:
                        next(f)
                        next(f)
                        reader = csv.reader(f, delimiter=',')
                        for row in reader:
                            if row[3] == 'cycles:u' and row[1].isnumeric():
                                sum_c_u += int(row[1])
                                count+=1 # onldy increase count if any value is actually updated
                            elif row[3] == 'cycles:k' and row[1].isnumeric():
                                sum_c_k += int(row[1])
                                count+=1
                            elif row[3] == 'instructions:u' and row[1].isnumeric():
                                sum_i_u += int(row[1])
                                count+=1
                            elif row[3] == 'instructions:k' and row[1].isnumeric():
                                sum_i_k += int(row[1])
                                count+=1
                        count = count / 4
                        average_cycles_u = int(sum_c_u / count)
                        average_cycles_k = int(sum_c_k / count)
                        average_instructions_u = int(sum_i_u / count)
                        average_instructions_k = int(sum_i_k / count)
                        rate, metric = name.split(".")
                        policy = os.path.basename(path.rstrip("/"))
                        key = f"{policy} ({rate})"
                        cycles_u[key] = average_cycles_u
                        cycles_k[key] = average_cycles_k
                        instructions_u[key] = average_instructions_u
                        instructions_k[key] = average_instructions_k
    # Cycle count
    cycle_counts = {
        "User": [],
        "Kernel": [],
    }
    # Instruction count
    instr_counts = {
    "User": [],
    "Kernel": [],
    }
    for key in cycles_u.keys():
        cycle_counts["User"].append(cycles_u[key])
        cycle_counts["Kernel"].append(cycles_k[key])
        instr_counts["User"].append(instructions_u[key])
        instr_counts["Kernel"].append(instructions_k[key])

    # Plot Instructions
    width = 0.9
    fig, ax = plt.subplots()
    bottom = np.zeros(27)

    for i, boolean in enumerate(cycle_counts.keys()):
        ins_count = instr_counts[boolean]
        labels = np.array(list(instructions_u.keys()))
        p = ax.barh(labels, ins_count, width, label=boolean, left=bottom)
        bottom += ins_count

    ax.set_title(f"Instruction Counts for {NUM_CPUS} CPU")
    ax.legend(loc="upper right")

    # Save and Plot
    #plt.savefig('<save-path>/<img>.png')
    plt.show()

    # Plot Cycles
    fig, ax = plt.subplots()
    bottom = np.zeros(27)

    for i, boolean in enumerate(cycle_counts.keys()):
        cycles_count = cycle_counts[boolean]
        labels = np.array(list(cycles_u.keys()))
        p = ax.barh(labels, cycles_count, width, label=boolean, left=bottom)
        bottom += cycles_count

    ax.set_title(f"Cycle Counts for {NUM_CPUS} CPU")
    ax.legend(loc="upper right")

    # Save and Plot
    #plt.savefig('<save-path>/<img>.png')
    plt.show()


# RUN ALL
prep_data()
plot_mpkis()
plot_ipmispredicts()
plot_cycles_instrs()