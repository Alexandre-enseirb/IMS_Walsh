function [sigComplexI, sigComplexQ] = hilbertTransform(sigReel, carrierFrequency, samplingFrequency, isWalsh, params)
%HILBERTTRANSFORM Summary of this function goes here
%   Detailed explanation goes here

if ~exist("isWalsh", "var")
    isWalsh=false;
end

if ~exist("params", "var")
    if isWalsh
        error("Params mandatory if isWalsh");
    else
        params = [];
    end
end


% Extraction du signal analytique et de la TH de s
sigAnalytic = 1/2 * hilbert(sigReel);
sigHilbert = 1j * ( sigReel - 2 * sigAnalytic );

timeAxis = ((1:length(sigReel))/samplingFrequency).';

if isWalsh
    cosine = real(wse(exp(1j*2*pi*carrierFrequency*timeAxis), params, length(timeAxis)));
    sine = imag(wse(exp(1j*2*pi*carrierFrequency*timeAxis), params, length(timeAxis)));
    freqFilter = zeros(size(freqAxis));
    freqFilter(freqAxis > -8e9 && freqAxis < 8e9) = 1;
    cosineFilt = ifft(fft(cosine, params.Nfft) * freqFilter, params.Nfft);
    sineFilt = ifft(fft(sine, params.Nfft) * freqFilter, params.Nfft);
    sigComplexI = real(sigReel .* cosineFilt + ...
        sigHilbert .* sineFilt );
    sigComplexQ = real(sigHilbert .* cosineFilt - ...
        sigReel .* sineFilt);

else
    % Signal sur les voies I et Q
    % le "real" permet de repasser a des doubles
    % En le retirant, la partie imaginaire de slI et slQ vaut 0i
    % Note: La projection sur cos/sin permet aussi de demoduler directement
    % le signal
    sigComplexI = real(sigReel .* cos(2*pi*carrierFrequency*timeAxis) + ...
        sigHilbert .* sin(2*pi*carrierFrequency*timeAxis));
    sigComplexQ = real(sigHilbert .* cos(2*pi*carrierFrequency*timeAxis) - ...
        sigReel .* sin(2*pi*carrierFrequency*timeAxis));
end

end

