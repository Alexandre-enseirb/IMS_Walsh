function [subsampleTime] = findBestSubSample(signal, oversamplingRate, observedDuration, modulationOrder, offset)
%FINDBESTSUBSAMPLE trouve le meilleur instant d'echantillonnage pour un signal surechantillonne module en M-PSK
%
% Le signal est eleve a la puissance M afin de replier la constellation sur un seul symbole, puis la variance de ce
% symbole est calculee. Le meilleur instant de sous-echantillonnage est celui avec la variance minimale (minimum d'IES)

if ~exist("offet", "var")
    offset=0;
end

% Allocation memoire
variances = zeros(1, oversamplingRate);

% Repliement de la constellation du signal
signal = signal.^modulationOrder;

[l,c] = size(signal);

% Verification des dimensions du signal
if l > 1 && c > 1 || l == 1 && c == 1
    error("The input signal has to be a vector");
elseif length(signal) < oversamplingRate
    error("The input signal length has to be higher than the oversampling rate");
elseif l == 1 && c > 1
    signal = signal.';
end

observedSignals = reshape(signal(offset+1:offset+oversamplingRate*observedDuration), oversamplingRate, observedDuration); % chaque ligne devient un signal sous-echantillonne
variances = var(observedSignals, 0, 2); % variance par ligne

[~, subsampleTime] = min(variances);
