function [sig] = walsh(Xw_b, W, Nfft, osr, freq)
%WALSH Summary of this function goes here
%   Detailed explanation goes here

if ~exist("freq", "var")
    freq=true;
end

[N, nWin] = size(Xw_b);
sig.temporel = zeros(N*nWin, 1);
for i=1:nWin
    sig.temporel((i-1)*N+1:i*N) = W*Xw_b(:,i);
end

sig.temporel = oversample_(sig.temporel, osr);
if freq
    sig = analyze(sig, Nfft);
end
sig.Xw_b = Xw_b;
sig.sum_Xw_b = sum(abs(Xw_b), 2);
end

