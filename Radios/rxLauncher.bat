@echo off
REM Remplacer cette variable par le dossier d'installation de MATLAB
set matlab=C:\Program Files\MATLAB\R2023a\bin\matlab.exe

REM Dans la variable `programName`, mettre le nom du script Matlab a lancer
REM (ex : `parallel_receiver`) SANS l'extension de fichier.
REM Sinon, MATLAB va etre perdu et lancer une erreur.

REM Ne pas mettre de guillemets autour du nom du fichier non plus
set programName=parallel_receiver

REM lance MATLAB sans affichages pour economiser des ressources et utiliser au
REM mieux les radios
start /B matlab -nodesktop -nosplash -batch "%programName%; exit;"

REM met l'invite de commande en pause tant qu'aucune action n'est realisee cote utilisateur
REM pas forcement utile actuellement mais interessant si on veut ecrire dans l'invite de commande
REM puis consulter les messages ecrits
pause