#!/usr/bin/env python3

import os
import sys
import subprocess
import json
# Added imports for parallel processing
import argparse
from multiprocessing import Pool

## execute a JSON configuration
def executeConfig(cellibpath, shellScriptName, dbpath, subdir, config):
    for fileName in config["files"]:
        hdlsrc = os.path.join(subdir, fileName)
        filewithoutext, file_extension = os.path.splitext(fileName)
        datfile = open(os.path.join(dbpath, filewithoutext + ".dat"), "wt")
        print("  Running HDL file " + fileName)
        retval = subprocess.check_call([os.path.abspath("./scripts/"+shellScriptName+".sh"), os.path.abspath("./" +hdlsrc), celllibpath],
                                cwd=os.path.abspath(subdir),
                                stdout=datfile,
                                stderr=sys.stderr
                                )
        datfile.close()
    return

# Process a single Verilog file
def process_verilog(args):
    subdir, item, celllibpath, shellScriptName, dbpath = args
    verilogsrc = os.path.join(subdir, item)
    filewithoutext, file_extension = os.path.splitext(item)
    datfile = open(os.path.join(dbpath, filewithoutext + ".dat"), "wt")
    print("  Running Verilog file " + item)
    retval = subprocess.check_call([os.path.abspath("./scripts/"+shellScriptName+".sh"), os.path.abspath("./" +verilogsrc), celllibpath],
                                cwd=os.path.abspath(subdir),
                                stdout=datfile,
                                stderr=sys.stderr
                                )
    datfile.close()
    return item

# Process a single VHDL file
def process_vhdl(args):
    subdir, item, celllibpath, shellScriptName, dbpath = args
    vhdlsrc = os.path.join(subdir, item)
    filewithoutext, file_extension = os.path.splitext(item)
    datfile = open(os.path.join(dbpath, filewithoutext + ".dat"), "wt")
    print("  Running VHDL file " + item)
    retval = subprocess.check_call([os.path.abspath("./scripts/"+shellScriptName+".sh"),os.path.abspath("./" +vhdlsrc), celllibpath],
                                cwd=os.path.abspath(subdir),
                                stdout=datfile,
                                stderr=sys.stderr
                                )
    datfile.close()
    return item

##########################################################################################
## MAIN PROGRAM STARTS HERE
##########################################################################################

# Parse command line arguments
parser = argparse.ArgumentParser(description='Run benchmarks with optional parallel processing')
parser.add_argument('mode', help='The benchmark mode to run')
parser.add_argument('dirs', nargs='+', help='Directories to process')
parser.add_argument('-j', '--jobs', type=int, default=8, help='Number of parallel jobs (default: 8)')
args = parser.parse_args()

shellScriptName = args.mode
dbpath = os.path.abspath("./database/"+shellScriptName)
celllibpath = os.path.abspath("./celllibs")

os.system("rm -rf "+dbpath)
os.system("mkdir -p "+dbpath)

# call all generate.py scripts
for dir in args.dirs:
    for subdir, dirs, files in os.walk(dir):
        for file in files:
            if (file == "generate.py"):
                script = os.path.join(subdir, file)
                print("Executing " + script)
                retval = subprocess.check_call(["python3","generate.py"], 
                                               cwd=os.path.abspath(subdir),
                                               stdout=sys.stdout,
                                               stderr=sys.stderr
                                               )

# Lists to collect tasks for parallel execution
verilog_tasks = []
vhdl_tasks = []

# First pass: collect all tasks
dir = args.dirs[0]  # Process only the first directory as in the original script
queue = [ dir ]
print("Processing directory: " + dir)
while queue:
    subdir = queue.pop()
    listdir = os.listdir(subdir)
    # Do not enter git repositories
    if '.git' in listdir: continue
    for item in listdir:
        path = os.path.join(subdir, item)
        if os.path.isdir(path):
            queue.append(path)
        elif os.path.isfile(path):
            # check if there is a config.json file
            if item == 'config.json':
                print("  Running config file: " + item)
                with open(path, 'r') as configFile:
                    try:
                        config = json.load(configFile)
                        # Config files are processed immediately, not in parallel
                        executeConfig(celllibpath, shellScriptName, dbpath, subdir, config)
                    except ValueError as error:
                        print("  --- ERROR PARSING CONFIG.JSON ---")
                        pass
            elif (item.endswith(".v")):
                # skip all files that end in _tb.v as they are testbench files
                # containing unsynthesizable code
                if (item.endswith("_tb.v")):
                    print("  Skipping Verilog testbench file " + item)
                    continue
                # skip any netlist files that might have been produced in 
                # previous runs
                if (item.endswith("_netlist.v")):
                    print("  Skipping Verilog netlist file " + item)
                    continue
                
                # Collect Verilog tasks instead of processing immediately
                verilog_tasks.append((subdir, item, celllibpath, shellScriptName, dbpath))
                    
            elif (item.endswith(".vhdl")):
                # Collect VHDL tasks instead of processing immediately
                vhdl_tasks.append((subdir, item, celllibpath, shellScriptName, dbpath))

# Second pass: execute collected tasks in parallel
if verilog_tasks or vhdl_tasks:
    total_tasks = len(verilog_tasks) + len(vhdl_tasks)
    print(f"\nExecuting {total_tasks} tasks using {args.jobs} parallel workers...")
    
    with Pool(processes=args.jobs) as pool:
        # Process Verilog files
        if verilog_tasks:
            verilog_results = pool.map(process_verilog, verilog_tasks)
            
        # Process VHDL files
        if vhdl_tasks:
            vhdl_results = pool.map(process_vhdl, vhdl_tasks)
    
    print(f"\nAll tasks completed. Processed {total_tasks} files.")