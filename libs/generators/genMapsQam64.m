function [maps] = genMapsQam64(f, params)
%GENMAPSQAM64 Summary of this function goes here
%   Detailed explanation goes here

T = lcm( ceil(1/f * params.fech), ceil(params.TRefresh_e) );

mapping = grayGen(6);
mapping_m = reshape(mapping, 8, 8);
mapping_qam = mapping_m;
mapping_inv = mapping_m;

mapping_qam(:,1:2:end) = flipud(mapping_m(:,1:2:end));

lin = 1:64;
mapping_inv(mapping_qam(:).' + 1) = lin;
mapping_inv = mapping_inv(:).';

maps.mapping_inv = mapping_inv;
maps.mapping_qam = mapping_qam;
maps.mapping_m = mapping_m;




maps.sinewave = sin(2*pi*f*params.timeAxis);

maps.Xw_b = cell(1,64);

for i=0:63
    s = wqammod(i, maps);
    maps.Xw_b{i+1} = dwt(s(1:params.osr:end), params.W, params.order, true);
    maps.walsh_wave{i+1} = walsh(maps.Xw_b{i+1}, params.W, params.Nfft, params.osr, true);
    maps.Xw_b_v(:,i+1) = maps.Xw_b{i+1}(:);
end

end

