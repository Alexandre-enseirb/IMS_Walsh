function [sigRx, piloteRx, preamble] = fineTimeSynchronization(signal, modulationOrder, phaseOffset)
%FINETIMESYNCHRONIZATION trouve le debut du signal synchronise grossierement en utilisant le
%preambule dans `bitSynchro.mat`.

load bitSynchro.mat

preamble = pskmod(bitSynchro, modulationOrder, phaseOffset, InputType="bit");
N = length(preamble);
p = intercorr(signal,preamble);
[mval,midx] = max(abs(p));

% récupération des 65536 symboles
piloteRx = signal(midx:midx + N-1);
sigRx = signal(midx+N:end);