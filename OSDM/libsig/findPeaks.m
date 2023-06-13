function [peaks, locs] = findPeaks(sig, mean_sz, smooth)
%FINDPEAKS Summary of this function goes here
%   Detailed explanation goes here
% WARNING: NO ERROR CHECK. User's discretion is advised.

if ~exist("mean_sz","var")
    mean_sz = 3;
end

if ~exist("smooth","var")
    smooth=false;
end

if smooth
% Make sig smoother so peaks due to noise aren't detected
    mean_filter = 1/mean_sz * ones(1,mean_sz);
    padded_sig = [sig(end-mean_sz+1:end) sig sig(1:mean_sz)];
    smooth_sig = conv(padded_sig, mean_filter, "same");
    smooth_sig = smooth_sig(mean_sz+1:end-mean_sz);
else
    smooth_sig = sig;
end
% Filter sig with a differential filter to detect sign changes of
% derivative
diff_filt = [1 -1];
diff_sig = conv(smooth_sig, diff_filt, "same");
sgn_chng = sign(diff_sig(1:end-1)) == sign(diff_sig(2:end));

% detect peaks
locs = find(sgn_chng == 0) + 1;
peaks = sig(locs);

end

