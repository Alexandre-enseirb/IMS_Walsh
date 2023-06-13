function [osr_sig] = oversample_(sig, osr)
%OVERSAMPLE_ Summary of this function goes here
%   Detailed explanation goes here

[l,c] = size(sig);

if l~=1 && c ~= 1
    warning("Conversion de matrice en vecteur");
    sig = sig(:);
end

if l~=1
    sig = sig.';
end

sig = repmat(sig, osr, 1);
osr_sig = reshape(sig, numel(sig), []);

end

