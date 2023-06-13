function [modulated_values] = qam64_fast(values, maps)
%QAM Summary of this function goes here
%   Detailed explanation goes here


mapping_m   = maps.mapping_m;
mapping_qam = maps.mapping_qam;
mapping_inv = maps.mapping_inv;

values_idx = mapping_inv(values+1);

[r,c] = ind2sub(size(mapping_m), values_idx);

modulated_values = (2*(c-1)-7) + 1j * (7-2*(r-1));

end

