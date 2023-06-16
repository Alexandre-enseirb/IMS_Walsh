@echo off
set matlab=C:\Program Files\MATLAB\R2023a\bin\matlab.exe

start /B matlab -nodesktop -nosplash -batch "parallel_transmitter; exit;" > tx_logs.txt

pause