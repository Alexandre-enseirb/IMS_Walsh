function [sfdr_value, in] = sfdr_peaks(spectrum, bw, freq_axis, fwalsh)
%SFDR Summary of this function goes here
%   Detailed explanation goes here

[peaks, locs] = findpeaks(spectrum);

% Limites de l'observation (bande de 0 a fWalsh/2)
middle = find(freq_axis == 0);
start  = find(freq_axis > bw(1), 1);
stop   = find(freq_axis > bw(2), 1) - 1;
fs2    = find(freq_axis > fwalsh/2, 1) - 1;

in_band = peaks(locs >= start & locs <= stop);
oo_band = peaks((locs > middle & locs < start) | (locs > stop & locs < fs2));

max_peak_oob = max(oo_band);
max_peak_inb = max(in_band);

sfdr_value = max_peak_inb - max_peak_oob;

% Le signal est "dans la bande" si le plus haut pic est dans la bande
in = max_peak_inb > max_peak_oob;

end

