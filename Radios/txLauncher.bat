@echo off
REM Remplacer cette variable par le dossier d'installation de MATLAB
set matlab=C:\Program Files\MATLAB\R2023a\bin\matlab.exe

REM Dans la variable `programName`, mettre le nom du script Matlab a lancer
REM (ex : `parallel_transmitter`) SANS l'extension de fichier.
REM Sinon, MATLAB va etre perdu et lancer une erreur.
set programeName = "parallel_transmitter"

start /B matlab -nodesktop -nosplash -batch "%programeName%; exit;" > tx_logs.txt

pause