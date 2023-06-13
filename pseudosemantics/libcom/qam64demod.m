function [symbols] = qam64demod(y, maps)
%QAM64DEMOD Summary of this function goes here
%   Detailed explanation goes here

[l,c] = size(y);
sig_ds_real = real(y);
sig_ds_imag = imag(y);

amps = -7:2:7;

if l~=1
    amps_m = repmat(amps, length(sig_ds_real), 1);
    dim = 2;
else
    amps_m = repmat(amps.', 1, length(sig_ds_real));
    dim = 1;
end


sig_ds_real_dist = abs(sig_ds_real - amps_m);
sig_ds_imag_dist = abs(sig_ds_imag - amps_m);

[~, val_r] = min(sig_ds_real_dist, [], dim);
[~, val_i] = min(sig_ds_imag_dist, [], dim);
val_i = 9 - val_i; % compensation

symbols = diag(maps.mapping_qam(val_i, val_r)).';

end
