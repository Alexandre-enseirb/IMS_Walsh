
function [sig] = getRandomConformedSignal(params, time_axis)
%GETRANDOMCONFORMEDSIGNAL genere un signal conforme
%
%   [sig] = GETRANDOMCONFORMEDSIGNAL(params) utilise des parametres generes
%   par la fonction GENPARAMS pour creer une somme de sinusoides respectant
%   la bande de frequences specifiee, et sa transformee de Walsh

% Axe des temps
if ~exist("time_axis", "var")
    time_axis  = (1:params.nWalsh)/params.fech;
end
% Frequences aleatoires a utiliser
f = randi([params.BW.span(1) params.BW.span(2)], 1, params.nFreqs);
% idx = randperm(length(params.bw_axis),params.nFreqs);
% f = params.bw_axis(idx);
% Generation du signal
% Signal temporel
sig.temporel          = sum(exp(1j*2*pi*f.'*time_axis));
% Signal frequentiel
sig.frequentiel       = fft(sig.temporel, params.Nfft);
% Transformee de Walsh
[sig.walsh, sig.Xw_b] = wse(sig.temporel, params, params.nWalsh);
% Transformee de Fourier de la transformee de Walsh
sig.walsh_fft         = fft(sig.walsh, params.Nfft);
% Sommation des coeffs de Walsh
sig.sum_Xw_b = sum(abs(sig.Xw_b), 2);
