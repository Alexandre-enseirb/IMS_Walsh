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


modulatedCoeffs = selectModulationCoefficients(nQAMSymbPerOSDMSymb, carrier.Clusters{2}, params);

%% SIMU

SNR = 10^(5/10);
attenuationFactor = 5;

idxSymb  = randi([1,64], nQAMSymbPerOSDMSymb, nSymbOSDMTx);

% Modulation et surechantillonnage
Sk             = qam64_fast_fast(idxSymb, params.maps);
Sk             = reshape(Sk, nQAMSymbPerOSDMSymb, []);

sl_      = zeros(size(carrier.walsh.temporel));

coeffs         = real(carrier.walsh.Xw_b);
upsampledSymbs = zeros(nQAMSymbPerOSDMSymb, symbOSDMDuration/nSymbOSDMTx * size(Sk, 2));
for i=1:nQAMSymbPerOSDMSymb
    upsampled_symb      = upsample_(Sk(i,:), symbOSDMDuration/nSymbOSDMTx * size(Sk, 2));
    upsampledSymbs(i,:) = upsampled_symb;
end
coeffs(modulatedCoeffs,:) = real(upsampledSymbs.*coeffCarrier) / attenuationFactor;
slStruct                          = walsh(coeffs, params.W, params.Nfft, params.osr, false);
sl = slStruct.temporel;

s = real(sl);

% Extraction des coeffs + simulation DAC
[sWalsh, XWalsh] = wse(s, params, length(s));

% Conformity verification
sigRecFFT = fftshift(fft(sWalsh, params.Nfft));
sigRecPow = abs(sigRecFFT).^2;
sigRecdB  = 10*log10(sigRecPow/max(sigRecPow));

if ~isConform(sigRecdB(nullFrequencyIdx:maxConformFrequency), params.BW_visible(nullFrequencyIdx:maxConformFrequency).')
    nNotConform = 1;
end

% Canal
% Noise power estimation
Psig   = 1/length(sWalsh) * sum(abs(sWalsh).^2);
Pbruit = Psig/SNR;

% Noise
b = sqrt(Pbruit)*randn(size(sWalsh));

y = sWalsh + b;

% Rx
% DWT
coeffsReception = dwt(y(1:params.osr:end) * attenuationFactor, params.W, params.order, true);

% DAC
coeffsReception = quantification(coeffsReception, params.nBitsAmp, params.max_bin);

% Reconstruction numerique du signal

% Generation de la sous-porteuse au niveau du recepteur
carrierCoeffs = dwt(coeffCarrier(1,:), params.W, params.order, true);
walshCarrier  = walsh(carrierCoeffs, params.W, params.Nfft, params.osr, false);
Wcosine       = real(walshCarrier.temporel).';
Wsine         = imag(walshCarrier.temporel).';

% Recuperation de l'enveloppe complexe par Hilbert
Xw_TxImag = hilbertWalsh(coeffsReception, params.W);

% Generation des signaux I/Q
Xw_TxCI = coeffsReception(modulatedCoeffs,:) .* Wcosine(1:length(coeffsReception)) + Xw_TxImag(modulatedCoeffs, :).* Wsine(1:length(coeffsReception));
Xw_TxCQ = Xw_TxImag(modulatedCoeffs, :).* Wcosine(1:length(coeffsReception)) - coeffsReception(modulatedCoeffs,:).* Wsine(1:length(coeffsReception));

% Combinaison des signaux, compensation et extraction des coeffs d'interet
Xw_TxCSymb                  = (Xw_TxCI + 1j*Xw_TxCQ);
Xw_TxC                      = coeffs;
Xw_TxC(modulatedCoeffs,:) = Xw_TxCSymb;

% Statistiques
positionSymbolesI = find(Wcosine(1:params.osr:end) > 1-threshold);
positionSymbolesQ = find(Wsine(1:params.osr:end) > 1-threshold);

extractedSymbolsI = real(Xw_TxC(modulatedCoeffs, positionSymbolesI));
extractedSymbolsQ = imag(Xw_TxC(modulatedCoeffs, positionSymbolesQ));
extractedSymbols  = zeros(length(modulatedCoeffs), nSymbOSDMTx);

separatedSymbols = reshape(extractedSymbolsI.', nRefreshPerSymbol/2, []) + 1j * reshape(extractedSymbolsQ.', nRefreshPerSymbol/2, []);
meanSymbols = mean(separatedSymbols, 1);
finalSymbols = reshape(meanSymbols, [], nQAMSymbPerOSDMSymb).';

finalSymbolsV = finalSymbols(:);
%extractedSymbolsPreMean = reshape(extractedSymbols.', nRefreshPerSymbol/2, []);
idxSymbTrsp             = idxSymb.';

symbolsRxIdx            = qam64demod(finalSymbolsV, params.maps) + 1;
symbolsRxBinary         = int2bit(symbolsRxIdx, M, true);
symbolsTxBinary         = int2bit(idxSymb(:).', M, true);
bitErrors = sum(symbolsTxBinary~=symbolsRxBinary, "all");

%% AFFICHAGE

figure("Name", "Spectrum", "Position", figurePos)
plot(params.freq_axis, sigRecdB, "DisplayName", "Semantic signal", "LineWidth", 2);
hold on; grid on;
plot(params.freq_axis, params.BW_visible, "DisplayName", "Mask", "LineWidth", 2, "LineStyle", "--");
xlim([0 4e9]);
xlabel("Frequency, Hz", "FontSize", 22, "Interpreter", "latex");
ylabel("Power, dB", "FontSize", 22, "Interpreter", "latex");
legend("Interpreter", "latex", "FontSize", 22, "Location", "southeast");

figure("Name", "Coeffs", "Position", figurePos)
plot(params.freq_axis, abs(fftshift(fft(params.W(modulatedCoeffs(1),:), params.Nfft))), "DisplayName", string(modulatedCoeffs(1)));
hold on; grid on;
plot(params.freq_axis, abs(fftshift(fft(params.W(modulatedCoeffs(2),:), params.Nfft))), "DisplayName", string(modulatedCoeffs(2)));
plot(params.freq_axis, abs(fftshift(fft(params.W(modulatedCoeffs(3),:), params.Nfft))), "DisplayName", string(modulatedCoeffs(3)));
legend("Interpreter", "latex", "FontSize", 22)