function [references] = loadWalshReferences64QAM(f0, duration, params)
%LOADWALSHREFERENCES64QAM load the matrix of reference coefficients for a 64-QAM communication over
%Walsh sequences
%
%   [references] = LOADWALSHREFERENCES64QAM(f0, duration, fe) looks for a file named
%   "walshReferences<duration>@<f0>.mat" in the folder data/walsh64qam, with <duration> replaced by the value 
%   of duration and <f0> replaced by the value of f0. 
%   The duration parameter is the number of refreshes to be performed and f0 is the carrier frequency.
%   If the file does not exist, the references are computed and saved as this file.

foldername = "data/walsh64qam/";
filename = sprintf("walshReferences%d@%d.mat", duration, f0);
fullName = strcat(foldername, filename);

if isfile(fullName)
    references = load(fullName);
else
    references = computeReferences(f0, duration, fe);
end

end

function [references] = computeReferences(f0, duration, params)
%COMPUTEREFERENCES create a file for the reference 64QAM Walsh coefficients

maps = genMapsQam64(f0, params);
coef = qam64_fast_fast(1:64, maps);

end

