function [phaseOffsetOrigin] = fineFrequencySynchronization(signal, piloteRx, preamble)
%FINEFREQUENCYSYNCHRONIZATION retrouve la phase a l'origine de la modulation a partir de la comparaison entre le
%preambule recu et le preambule envoye

N = length(piloteRx);

err = 1/N * sum(piloteRx .* conj(preamble)./abs(preamble).^2);
phaseOffsetOrigin = angle(err);