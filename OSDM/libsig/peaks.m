function [peak_vals, peak_locs] = peaks(sig, thresh)
%PEAKS Summary of this function goes here
%   Detailed explanation goes here

len = length(sig);
axis = 1:len;
diff_sig = diff(sig);

crossings = (sign(diff_sig(1:end-1)) ~= sign(diff_sig(2:end)));

l = axis(crossings);
peak_vals = sig(l);
peak_locs = l;

above_thresh = peak_vals > thresh;

peak_vals = peak_vals(above_thresh);
peak_locs = peak_locs(above_thresh);
end

