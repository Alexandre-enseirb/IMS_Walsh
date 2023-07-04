function [modulatedValues] = qam64_fast_fast(values, maps)
%QAM Summary of this function goes here
%   Detailed explanation goes here


mapping_m   = maps.mapping_m;
mapping_qam = maps.mapping_qam;
mapping_inv = maps.mapping_inv;

values_idx = mapping_inv(values);
if size(values, 1) ~= size(values_idx, 1)
    values_idx = values_idx.';
end
[h,w] = size(mapping_m);

r = rem(values_idx-1, h)+1;
c = (values_idx-r)/h + 1;


modulatedValues = (2*(c-1)-7) + 1j * (7-2*(r-1));

end

