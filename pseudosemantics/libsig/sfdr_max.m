function [sfdr_value, in] = sfdr_max(spectrum, middle, start, stop, fs2)
%SFDR Summary of this function goes here
%   Detailed explanation goes here

in_band  = spectrum(start:stop);
oo_band1 = spectrum(middle:start);
oo_band2 = spectrum(stop:fs2);

max_peak_oob = max(max(oo_band1), max(oo_band2));
max_peak_inb = max(in_band);

sfdr_value = max_peak_inb - max_peak_oob;

% Le signal est "dans la bande" si le plus haut pic est dans la bande
in = max_peak_inb > max_peak_oob;

end

