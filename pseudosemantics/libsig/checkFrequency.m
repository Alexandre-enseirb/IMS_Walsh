function [results] = checkFrequency(coeffs, maxval, params)
%CHECKFREQUENCY verifie la conformite du signal de Walsh cree a partir
%d'une liste de coefficients.
%
%   results = checkFrequency(coeffs, params) utilise les coefficients
%   definis dans coeffs et les parametres donnes par params pour s'assurer
%   de la conformite du signal a la bande de frequences et a la SFDR
%   demandees.
%
%   Cette verification se fait pour chaque combinaison d'amplitudes entre
%   -maxval-1 et maxval. results contient sur les lignes les combinaisons
%   d'amplitudes ayant passe le check.
%
%   Pour chaque combinaison d'amplitude, le signal de Walsh est recompose,
%   puis sa fft est calculee. De son spectre on deduit la SFDR, et
%   l'emplacement des pics principaux. Si le pic a 0 dB est hors de la
%   bande passante, ou si la SFDR n'est pas suffisante, la combinaison est
%   rejetee.
fprintf("Checking frequencies... ");
maxamp = 2^params.nBitsAmp;
minval = -maxval;
nbCoeffs = length(coeffs);
amplitudes = [maxval minval*ones(1,nbCoeffs-1)];

results = {};

if minval < maxval
    direction="ascend";
else
    direction="descend";
end

firstLoop = true;

while sum(amplitudes(2:end)==abs(maxval))~=nbCoeffs-1 | firstLoop
    Xw_b = zeros(1,64);
    Xw_b(coeffs) = amplitudes;
    if check(Xw_b, params)
        results{end+1} = amplitudes;
    end
    if firstLoop
        firstLoop=false;
    end
    amplitudes(2:end) = update_amp(amplitudes(2:end), maxval, 1/maxamp, direction);
end
fprintf("DONE!\n");
end

function [good] = check(Xw_b, params)
%CHECK verifie pour une combinaison de coeffs donnes si cette combinaison
%donne un signal conforme

sig_Walsh = Xw_b*params.W;

sig_Walsh_fft = fft(sig_Walsh, params.Nfft);

power_spectrum = 20*log10(abs(sig_Walsh_fft)/max(abs(sig_Walsh_fft)));

[sfdr_val, in] = sfdr_max(power_spectrum, params.middle, params.start, params.stop, params.fs2);

good = in & sfdr_val <= params.sfdr_out;
    
end