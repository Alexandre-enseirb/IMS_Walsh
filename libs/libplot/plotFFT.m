function [sigFFT] = plotFFT(sigTime, axh, name, Nfft, normalizedFrequency)
%PLOTFFT Summary of this function goes here
%   Detailed explanation goes here

if ~exist("name", "var")
    name = "Data";
end

if ~exist("Nfft", "var")
    Nfft = 8192;
end

if ~exist("normalizedFrequency", "var")
    normalizedFrequency = false;
end

sigFFT = fftshift(fft(sigTime, Nfft));

freqAxis = -1/2:1/Nfft:1/2-1/Nfft;

if ~normalizedFrequency
    freqAxis = freqAxis * Nfft;
end

plot(axh, freqAxis, abs(sigFFT), "DisplayName", name, "LineWidth", 1.5);



end

