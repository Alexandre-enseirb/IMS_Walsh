function [modulated_values] = qam64(values)
%QAM Summary of this function goes here
%   Detailed explanation goes here

mapping = grayGen(6);
mapping_m = reshape(mapping, 8, 8);
mapping_qam = mapping_m;
mapping_inv = mapping_m;

mapping_qam(:,1:2:end) = flipud(mapping_m(:,1:2:end));

lin = 1:64;
mapping_inv(mapping_qam(:).' + 1) = lin;
mapping_inv = mapping_inv(:).';


values_idx = mapping_inv(values+1);

[r,c] = ind2sub(size(mapping_m), values_idx);

modulated_values = (2*(c-1)-7) + 1j * (7-2*(r-1));

end

