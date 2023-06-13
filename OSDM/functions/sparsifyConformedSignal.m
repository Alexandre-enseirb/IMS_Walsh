function [sparse_signal] = sparsifyConformedSignal(signal, params, std, method)
%SPARSIFYCONFORMEDSIGNAL Summary of this function goes here
%   Detailed explanation goes here


if ~exist("method", "var")
    method="std";
end

sparse_signal = sparsifyByStandardDeviation(signal, std, params.sparsify_amnt, params.W, params.Nfft, params.osr);
end

function [sparse_signal] = sparsifyByStandardDeviation(signal, std, n, W, Nfft, osr)

[~, perm_table] = sort(std, 'ascend');

idx_to_sparsify = perm_table(1:n);

signal.Xw_b(idx_to_sparsify,:) = 0;

sparse_signal = walsh(signal.Xw_b, W, Nfft, osr);
end

