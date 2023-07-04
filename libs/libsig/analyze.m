function [sig] = analyze(sig, Nfft)
%ANALYZE Summary of this function goes here
%   Detailed explanation goes here

sig.frequentiel = fftshift(fft(sig.temporel, Nfft));
sig.spectre     = abs(sig.frequentiel);
sig.pow         = sig.spectre.^2;
sig.dB          = 20*log10(sig.pow/max(sig.pow));


end

