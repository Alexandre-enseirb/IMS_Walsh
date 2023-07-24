function [sigRx, piloteRx, preambleSymb] = fineTimeSynchronization(signal, modulationOrder, phaseOffset)
%FINETIMESYNCHRONIZATION trouve le debut du signal synchronise grossierement en utilisant le
%preambule dans `bitSynchro.mat`.

load("bitSynchro.mat", "bitSynchro");

preambleSymb = pskmod(bitSynchro, modulationOrder, phaseOffset, InputType="bit"); % Preambule module
N = length(preambleSymb);

p = intercorr(signal, preambleSymb); % Calcul d'intercorrelation simplifie entre le signal et le preambule genere
[~,midx] = max(abs(p));              % Recherche du maximum d'intercorrelation

% recuperation des 65536 symboles
piloteRx = signal(midx:midx + N-1); % Extraction du pilote
sigRx = signal(midx+N:signal);         % Extraction de ce que l'on suppose etre l'image