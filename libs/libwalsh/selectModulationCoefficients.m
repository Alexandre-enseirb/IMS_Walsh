function [coefficients] = selectModulationCoefficients(nCoefficientsToSelect, cluster, params, idxFirstCoeff)
%SELECTMODULATIONCOEFFICIENTS Summary of this function goes here
%   Detailed explanation goes here
coefficients = zeros(nCoefficientsToSelect, 1);

if ~exist("idxFirstCoeff", "var")
    coefficients(1) = randsample(cluster, 1);
else
    coefficients(1) = cluster(idxFirstCoeff);
end




fftWalsh = zeros(length(cluster), params.Nfft);

for iFFT = 1:length(cluster)
    fftWalsh(iFFT, :) = abs(fftshift(fft(params.W(cluster(iFFT, :), :), params.Nfft)));
    fftWalsh(iFFT, :) = 20*log10(fftWalsh(iFFT,:)/max(fftWalsh(iFFT,:)));
    
end

fftWalsh(fftWalsh==-Inf) = -300;

for iCoeff=2:nCoefficientsToSelect
    correlation = zeros(length(cluster), 1);
    for iSub = 1:iCoeff-1
        correlation = correlation + correlationNoLag(fftWalsh(cluster==coefficients(iSub), :), fftWalsh);
    end
    [~, newCoefficient] = min(correlation);
    coefficients(iCoeff) = cluster(newCoefficient);
end

end

function [correlation] = correlationNoLag(sigToAnalyze, otherSigs)

correlation = sum(sigToAnalyze.*otherSigs, 2);

end
