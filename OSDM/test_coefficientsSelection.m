clear; clc; close all; dbstop if error;

set_path();

%% PARAMETRES
% rng(12);
params = genParamsOSDM(2.4825e9, ...
    2.495e9, ...
    10e6, ...
    1e9, ...
    8e9, ...
    250e6, ...
    6, ...
    12, ...
    8, ...
    false, ...
    8e9, ...
    8e9, ...
    400);

M            = 6; % 64-QAM, 6 bits par symbole
carrier_name = sprintf("data/walsh_carrier_%d@%d_Hz_fd.mat", params.BW_middle_freq, params.fech);

figurePos = getFigPosition(); % Position and size of plots

nCarrierCoeffs = 12; % Nombre de coefficients jouant dans la "porteuse"

SNRdBMin  = 15;          % Signal-to-noise Ratio (dB)
SNRdBMax  = 15;
SNRdBStep = 0.5;

SNRdB = SNRdBMin:SNRdBStep:SNRdBMax;

nSNR = length(SNRdB);

targetDs    = 2.5e6;         % Symbols/s
nSymbOSDMTx = 1;           % symbols per frame
targetTs    = 1/targetDs;          % s
Te          = 1/params.fech; % s
fse         = ceil(targetTs/Te);   % no unit

nRefreshPerSymbol = fse/64;
if mod(nRefreshPerSymbol, 2) == 1 % Compensation des cas impairs
    nRefreshPerSymbol = nRefreshPerSymbol + 1;
    fse               = fse+64;
end

realTs           = fse*Te;
realDs           = ceil(1/realTs);
channelFrequency = 500e6;

ga    = 1/fse * ones(1, fse);  % Adapted filter
delay = mean(grpdelay(ga, 1));
delay = 2*delay + 1;


totalDuration    = ceil((nSymbOSDMTx/realDs)*params.fech); % signal duration
symbOSDMDuration = totalDuration/(params.nCoeff*params.osr);
timeAxis         = (1:totalDuration)/params.fech;

freqAxis = params.freq_axis;

params.nullFrequencyIdx    = ceil(length(params.freq_axis)/2);
params.maxConformFrequency = find(params.freq_axis > params.fWalsh/2, 1);
if isempty(params.maxConformFrequency)
    params.maxConformFrequency = params.Nfft;
end

% Generation porteuses

[carriers, stats] = generateWalshCarrierFixedDurationClusterize(params, 100, carrier_name, totalDuration, [4 32 64-32-4]);

% Extraction de la 1ere porteuse (les deux sont equivalentes)
carrier             = carriers{1};
nQAMSymbPerOSDMSymb = 3;
nSymbTx             = nQAMSymbPerOSDMSymb*nSymbOSDMTx;
threshold           = 5e-3;

% modulatedCoeffs = carriers{1}.Clusters{2};
% modulatedCoeffs = randsample(modulatedCoeffs, nQAMSymbPerOSDMSymb);
nCoeffsToSelect = 3;
cluster = carrier.Clusters{2};
nSymbolsCombinationsPerCoefficientsCombinations = 256;
nCombinationsToGenerate = 16384;

lengthUpsampled       = symbOSDMDuration;

% "Porteuse complexe" des coefficients, pour pouvoir appliquer Hilbert
coeffCarrier          = zeros(1, lengthUpsampled);
coeffCarrier(1:2:end) = 1;
coeffCarrier(2:2:end) = 1j;

tic;
modulatedCoeffsSum = improvedCoefficientsSelection(nCoeffsToSelect, ...
    cluster, ...
    carrier, ...
    nSymbolsCombinationsPerCoefficientsCombinations, ...
    nQAMSymbPerOSDMSymb, ...
    nSymbOSDMTx, ...
    nCombinationsToGenerate, ...
    symbOSDMDuration, ...
    coeffCarrier, ...
    4, ...
    true, ...
    params);
t1 = toc;

tic;
modulatedCoeffsWalsh = improvedCoefficientsSelectionv2(nCoeffsToSelect, ...
    cluster, ...
    carrier, ...
    nSymbolsCombinationsPerCoefficientsCombinations, ...
    nQAMSymbPerOSDMSymb, ...
    nSymbOSDMTx, ...
    nCombinationsToGenerate, ...
    symbOSDMDuration, ...
    coeffCarrier, ...
    4, ...
    true, ...
    params);
t2 = toc;

fprintf("Sum took %.3f s\nWalsh took %.3f s\n", t1, t2);

% save("Combinations_with_sum_approach_n53.mat", "modulatedCoeffsSum");
% save("Combinations_with_walsh_approach_n53.mat", "modulatedCoeffsWalsh");