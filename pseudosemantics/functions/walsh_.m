function [sig_Walsh, visual_BW] = walsh_(sig, params)
%WALSH Summary of this function goes here
%   Detailed explanation goes here
if exist("params.Fse","var")
    Fse=params.Fse;
else
    Fse = 1;
end
Xw = dwt(sig(1:params.Tse:end), params.order, true, Fse);
[~, nWindows] = size(Xw);

Xw_b = zeros(size(Xw));
sig_Walsh = zeros(1, params.Nech/2);
W = genWalsh(params.order);

for i=1:nWindows
    Xw_b(:,i) = quantification(Xw(:,i), params.nBitsAmp, params.max_bin);
    tmp = sum(W*diag(Xw_b(:,i)),2);
    sig_Walsh((i-1)*params.nCoeff+1:i*params.nCoeff) = tmp;
end

visual_BW = zeros(1, length(params.freq_axis));
visual_BW(params.freq_axis > params.BW(1)/2 & params.freq_axis < params.BW(2)/2) = 1;
end

