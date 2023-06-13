#! /bin/bash

MATLAB=/usr/local/MATLAB/R2023a/bin/matlab

touch VRX
nohup "$MATLAB" -nodisplay -nosplash -nodesktop -r "test_rx; exit;" > rx_logs.txt &
