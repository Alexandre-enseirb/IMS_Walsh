function [carriers, stats] = generateWalshCarrierFixedDurationClusterize(params, nIter, filename, duration, clustersSizes, coeffsAmnt)
%GENERATEWALSHCARRIER Summary of this function goes here
%   Detailed explanation goes here

if ~exist("coeffsAmnt", "var")
    coeffsAmnt = 32;
end

nClusters = length(clustersSizes);

if sum(clustersSizes) ~= params.nCoeff
    error("Sum of clusters sizes does not equal %d\n", params.nCoeff);
end


% variables
carriers = cell(1,2);

fc = params.BW_middle_freq; % carrier

sig = getRandomConformedSignal(params, params.time_axis);
nWindows = size(sig.Xw_b, 2);

stats.mem           = zeros(params.nCoeff, nIter);
stats.summed_coeffs = zeros(params.nCoeff, 1);
stats.mean_coeffs   = zeros(params.nCoeff, 1);
stats.var_coeffs    = zeros(params.nCoeff, 1);
stats.max_coeffs    = zeros(params.nCoeff, 1);
stats.std_c         = zeros(params.nCoeff, 1);
stats.mean_over_time = zeros(params.nCoeff, nWindows);
% Stats
for i=1:nIter
    sig = getRandomConformedSignal(params, params.time_axis);
    stats.mean_over_time = stats.mean_over_time + sig.Xw_b;
    stats.summed_coeffs = stats.summed_coeffs + sig.sum_Xw_b; 
    stats.mem(:,i)      = sig.sum_Xw_b;
    stats.mean_coeffs   = stats.summed_coeffs ./ i;             
    stats.max_coeffs    = max([sig.sum_Xw_b stats.max_coeffs], [], 2);
    stats.var_coeffs    = sum((stats.mem - stats.mean_coeffs).^2, 2)/i;
    stats.std_c         = sqrt(stats.var_coeffs);
end

stats.mean_over_time = stats.mean_over_time/(nIter*params.nFreqs);
[~, ordered_coeffs] = sort(stats.std_c, 'descend');

% Generation des porteuses
% Methode 1 - transformee de Walsh d'une porteuse sinusoidale

timeAxis = (1:duration)/params.fech;

c  = exp(1j*2*pi*fc*timeAxis);
[~, Xw_b_c] = wse(c, params, duration);
Xw_b_c(ordered_coeffs(coeffsAmnt+1:end),:) = 0;
carriers{1}.walsh  = walsh(Xw_b_c, params.W, params.Nfft, params.osr);
carriers{1}.coeffs = Xw_b_c;
carriers{1}.temporel = c;
coeffPtr = 1;
for iCluster=1:nClusters
    carriers{1}.Clusters{iCluster} = ordered_coeffs(coeffPtr:coeffPtr+clustersSizes(iCluster)-1);
end

% save(filename, "carriers", "stats");
end

