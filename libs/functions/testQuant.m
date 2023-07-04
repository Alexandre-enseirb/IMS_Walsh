function [coeffs_out] = testQuant(coeffs, nBits)
%TESTQUANT Basiquement comme quantification, mais a ma sauce

[l,c] = size(coeffs);

coeffs = coeffs(:);
max_interval = bi2de([0  ones(1, nBits-1)], 'left-msb');  % si n=8 : 0b01111111 =  127
min_interval = bi2de([1 zeros(1, nBits-1)], 'left-msb'); % si n=8 : 0b10000000 = -128

max_current = max(coeffs);
min_current = min(coeffs);

out_interval_sz = (max_interval - min_interval);
in_interval_sz  = (max_current - min_current);

coeffs_out = (coeffs - min_current / in_interval_sz) * out_interval_sz + min_interval;

coeffs_out = reshape(coeffs_out, l,c);
end

