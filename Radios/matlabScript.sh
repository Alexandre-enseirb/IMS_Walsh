#! /bin/bash

MATLAB=/usr/local/MATLAB/R2023a/bin/matlab

if [ $# -eq 1 ]; then
    nohup "$MATLAB" -nodisplay -nosplash -nodesktop -r "$1; exit;" > /tmp/logs.txt &
    exit 0
fi

if [ $# -ge 2 ]; then
    nohup "$MATLAB" -nodisplay -nosplash -nodesktop -r "$1; exit;" > $2 &  
    exit 0
fi

echo "Please specify script and redirect output"


