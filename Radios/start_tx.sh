#! /bin/bash

MATLAB=/usr/local/MATLAB/R2023a/bin/matlab

touch VTX
nohup "$MATLAB" -nodisplay -nosplash -nodesktop -r "test_tx; exit;" > tx_logs.txt &
