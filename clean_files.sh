#!/bin/bash
# filepath: clean_files.sh

echo "This script will recursively delete the following files from the current directory and subdirectories:"
echo "  - .vv files"
echo "  - yosys_.log files"
echo "  - vivado_*.log files"
echo "  - script*.yos files"
echo "  - vivado_script_*.tcl files"
echo ""

# Display files to be deleted
echo "The following files will be deleted:"
find . -type f -name "*.vv" 2>/dev/null
find . -type f -name "*_vivado.log.log" 2>/dev/null
find . -type f -name "*_yosys.log.log" 2>/dev/null
find . -type f -name "*_yosys.tcl" 2>/dev/null
find . -type f -name "*_vivado.tcl" 2>/dev/null
echo ""

# Ask for confirmation
read -p "Do you want to proceed with deletion? (y/n): " confirm
if [[ $confirm != [yY] && $confirm != [yY][eE][sS] ]]; then
    echo "Operation cancelled"
    exit 0
fi

# Delete files
echo "Deleting files..."
find . -type f -name "*.vv" -delete 2>/dev/null
find . -type f -name "*_vivado.log.log" -delete 2>/dev/null
find . -type f -name "*_yosys.log.log" -delete 2>/dev/null
find . -type f -name "*_yosys.tcl" -delete 2>/dev/null
find . -type f -name "*_vivado.tcl" -delete 2>/dev/null

echo "Deletion complete!"