@echo off
set matlab=C:\Program Files\MATLAB\R2023a\bin\matlab.exe

start /B matlab -nodesktop -nosplash -batch "parallel_receiver; exit;" > rx_logs.txt

pause