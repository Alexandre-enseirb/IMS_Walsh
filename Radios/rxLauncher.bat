@echo off
REM Remplacer cette variable par le dossier d'installation de MATLAB
set matlab=C:\Program Files\MATLAB\R2023a\bin\matlab.exe

REM Dans la variable `programName`, mettre le nom du script Matlab a lancer
REM (ex : `parallel_receiver`) SANS l'extension de fichier.
REM Sinon, MATLAB va etre perdu et lancer une erreur.
set programeName = "parallel_receiver"

start /B matlab -nodesktop -nosplash -batch "%programName%; exit;" > rx_logs.txt

pause