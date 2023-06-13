#! /bin/bash

MATLAB=/usr/local/MATLAB/R2023a/bin/matlab

touch VTX
touch VRX

nohup "$MATLAB" -nodisplay -nosplash -nodesktop -r "test_tx_qpsk; exit;" > tx_logs.txt &
nohup "$MATLAB" -nodisplay -nosplash -nodesktop -r "test_rx; exit;" > rx_logs.txt &
