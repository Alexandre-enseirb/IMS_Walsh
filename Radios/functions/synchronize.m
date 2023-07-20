function [sig, phaseOffsetOrigin] = synchronize(buffer1, buffer2, commParams, radioParams)
%SYNCHRONIZE fait la synchronisation temporelle et frequentielle d'un signal recu via `parallel_receiver.m`
%
% Deux buffers de longueur 2x la duree de la trame sont utilises pour garantir que l'un des deux contienne le
% signal dans son integralite.
% Le bloc detection du signal sert a detecter le debut et la fin du signal dans chacun de ces buffers afin 
% de l'isoler en vue de la suite du traitement.
% La synchronisation temporelle grossiere consiste a choisir le meilleur surechantillon pour
% minimiser l'interference entre symboles
% La synchronisation frequentielle grossiere elimine le dephasage constant qu'il existe entre l'emetteur et le
% recepteur (ou, en bon francais : "la constellation ne tourne plus")
% La synchronisation temporelle fine trouve le debut du signal a partir du preambule
% La synchronisation frequentielle fine trouve la phase a l'origine de la constellation recue
%
%   [synchronizedSignal] = synchronize(buffer1, buffer2, commParams, radioParams) utilise les deux
%   buffers specifies et les parametres donnes pour realiser toute la chaine de synchronisation du signal.
%   Les buffers sont a charger depuis un fichier externe ou a utiliser directement depuis `parallel_receiver.m`.


%% Bloc detection du debut du signal
offset = 800; % securite
[~, startIdxBuffer1, ~, flag1] = detectSignalStartEndV2(buffer1(:));
[~, startIdxBuffer2, ~, flag2] = detectSignalStartEndV2(buffer2(:));

% Ajout de l'offset et comparaison a 0
startIdxBuffer1 = max(1, startIdxBuffer1-offset);
startIdxBuffer2 = max(1, startIdxBuffer2-offset);

if flag1
    signal = buffer1(startIdxBuffer1:end);
elseif flag2
    signal = buffer2(startIdxBuffer2:end);
else
    error("No good buffer");
end


%% Bloc synchronisation temporelle grossiere
symbolTime = findBestSubSample(signal, commParams.fse, 100, commParams.ModOrderQPSK, 6000);

%% Bloc synchronisation frequentielle grossiere (PLL)
% synchronizedSignal = coarseFreqSync(signal, symbolTime, commParams.fse);
synchronizedSignal = signal(symbolTime:commParams.fse:end);

%% Bloc synchronisation temporelle fine
[sig, preambleRx, preambleTx] = fineTimeSynchronization(synchronizedSignal, commParams.ModOrderQPSK, commParams.PhaseOffsetQPSK);

%% Bloc synchronisation frequentielle fine
phaseOffsetOrigin = fineFrequencySynchronization(sig, preambleRx, preambleTx);

end