%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script principal pour la reception d'image.
%
% Cree le fichier temporaire "/tmp/radioRxflag" (linux) ou "C:\Users\Nom d'utilisateur\Local\Temp\radioRxflag"
% (Windows) et lance la boucle de reception contenue dans la fonction "imgRx".
%
% La lecture se fait par deux buffers decales de la duree du signal attendu. De ce fait, quel que soit l'instant
% auquel la transmission demarre, on sait qu'un des deux buffers contiendra le signal complet sans coupure.
%
% Le signal recu est ensuite sauvegarde avec ses parametres dans un fichier .mat pour etre traite ulterieurement
% (synchronisation et affichage du contenu)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; clc; close all; dbstop if error;

setPath();

%% PARALLEL POOL CREATION

flag    = fullfile(tempdir, "radioRxflag");


f = fopen(flag, "w+");
fwrite(f, int8(0), "int8");
fclose(f);

mflag    = memmapfile(flag, "Format", "int8" , "Writable", true);
imgRx(mflag);