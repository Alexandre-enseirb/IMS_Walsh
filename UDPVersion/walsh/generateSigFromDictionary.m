function [sig] = generateSigFromDictionary(entry, carrier, attenuation, params)
%GENERATESIGFROMDICTIONARY generates the modulated Walsh signal obtained via 'IMPROVEDCOEFFICIENTSSELECTION'.
%
%   [sig] = GENERATESIGFROMDICTIONARY(entry, carrier, attenuation, params) takes a nxm array or a 1x1 cell-array containing a nxm array as
%   inputs. n is the quantity of modulated coefficients, m is the number of windows + 1. The first line indicates
%   the index of the modulated coefficients. Lines 2 to end indicate the value of the symbol.
%   carrier is a 64xN array where 64 is the number of Walsh coefficients and N is the number of windows. It
%   contains the default values of every coefficient to reach the desired bandwidth.
%   params is a struct containing all the necessary parameters, generated via 'genParams'.

if iscell(entry)
    entry = entry{1};
end

nCoeffs = size(entry, 2);

modulatedCoeffs = entry(1,:);
Sk = entry(2:end, :).';


upsampledSymbols = zeros(nCoeffs, size(carrier, 2));
for i=1:nCoeffs
    upsampledSymbols(i,:) = upsample_(Sk(i,:), size(carrier, 2));
end

finalCoeffs = real(carrier);
finalCoeffs(modulatedCoeffs, :) = upsampledSymbols/attenuation;

sig = walsh(finalCoeffs, params.W, params.Nfft, params.osr, false);
sig = sig.temporel;

