function [sig, startIdx, endIdx, flag] = detectSignalStartEndV2(buffer)
%DETECTSIGNALSTARTEND detecte le debut et la fin du signal dans un buffer de radio
% Cette fonction se sert d'un enregistrement du bruit de la radio pour determiner
% la variance du bruit. On se fixe un seuil a 5x l'ecart-type du bruit et on
% detecte le debut et la fin du signal.
%
% Par mesure de securite, si un candidat (i.e. un echantillon d'amplitude superieur
% au seuil) est detecte parmi les 1000 premiers echantillons du signal, le buffer
% est considere comme "invalide" (le signal est en deux parties et se "replie" sur 
% debut du buffer)
%
%   [sig, startIdx, endIdx, flag] = detectSignalStartEndV2(buffer) retourne le
%   signal extrait, l'indice de debut, de fin, et le flag permettant de savoir si
%   le signal est bon ou mauvais.
%
% En cas de mauvais buffer, sig est une liste vide, startIdx et endIdx valent -1
% et flag vaut `false`.

% Vectorisation du buffer
buffer = buffer(:);

% Estiation de la variance du bruit et mise en place du seuil
[~, noiseVariance] = profileNoiseRadio();
threshold = 5*sqrt(noiseVariance);

% Detection du debut du signal
startIdx = find(real(buffer) > threshold, 1);

% Detecte un repliement du signal sur le debut du buffer
if startIdx < 1000
    sig = [];
    startIdx = -1;
    flag = false;
    endIdx = -1;
    return;
end

% Extrait le signal
flag = true;
candidates = find(real(buffer) > threshold);
endIdx = candidates(end);
sig = buffer(startIdx:endIdx);

    
end