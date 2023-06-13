%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                                                            %
% This file describes the whole processing chain for communication of 64 QAM symbols over Walsh              %
% functions.                                                                                                 %
%                                                                                                            %
% On the emitter's end, it generates the bitstream and modulates it as with any communication chain.         %
% The shaping filter used is a rectangular window to fit Walsh functions' shape. A complex carrier           %
% is used to bring the signal into the right bandwidth. Finally, the signal is transformed using             %
% Walsh and the coefficients are given to a DAC.                                                             %
%                                                                                                            %
% The channel is an infinite-bandwidth no-memory additive white gaussian noise channel                       %
%                                                                                                            %
% On the receiver's end, we suppose that the synchronization is done properly (via analog methods)           %
% and we are handed out the Walsh coefficients via 64 ADC. The real signal is digitally reproduced           %
% before its complex envelope is restored via Hilbert transform.                                             %
% Since the carrier signal is degraded due to the Walsh transform, an attenuation is visible on the          %
% symbols after adated filtering. This attenuation seems constant, and is learned via a pilot                %
% sequence. This allows for good decoding of the symbols.                                                    %
%                                                                                                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; clc; close all; dbstop if error;

set_path();

%% PARAMETRES
rng(0);
params = genParamsOSDM(2.4825e9, ...
                   2.495e9, ...
                   10e6, ...
                   1e9, ...
                   8e9, ...
                   250e6, ...
                   6, ...
                   15, ...
                   8, ...
                   false, ...
                   8e9, ...
                   8e9, ...
                   400);

M            = 6; % 64-QAM, 6 bits par symbole
carrier_name = sprintf("data/walsh_carrier_%d@%d_Hz_fd.mat", params.BW_middle_freq, params.fech);

figurePos = getFigPosition(); % Position and size of plots

SNRdB = 60;          % Signal-to-noise Ratio (dB)
SNR   = 10^(SNRdB/10); % Signal-to-noise Ratio (linear)

Ds          = 2.5e6;         % Symbols/s
nSymbOSDMTx = 100;           
Ts          = 1/Ds;          % s
Te          = 1/params.fech; % s
fse         = ceil(Ts/Te);   % no unit

channelFrequency = 500e6;

nNotConform = 0;

nRefreshPerSymbol = fse/64; 
totalDuration     = (nSymbOSDMTx/Ds)*params.fech; % signal duration
symbOSDMDuration  = totalDuration/(params.nCoeff*params.osr);
timeAxis          = (1:totalDuration)/params.fech;

freqAxis = params.freq_axis;

nullFrequencyIdx    = ceil(length(params.freq_axis)/2);
maxConformFrequency = find(params.freq_axis > params.fWalsh/2, 1);
if isempty(maxConformFrequency)
    maxConformFrequency = params.Nfft;
end

% Generation porteuses
if ~isfile(carrier_name)
    [carriers, stats] = generateWalshCarrierFixedDuration(params, 100, carrier_name, totalDuration);
else
    tmp      = load(carrier_name);
    carriers = tmp.carriers;
    stats    = tmp.stats;
    %clear("tmp");
end
carrier             = carriers{1};
nQAMSymbPerOSDMSymb = length(carrier.available);
nSymbTx = nQAMSymbPerOSDMSymb*nSymbOSDMTx;

ga    = 1/fse * ones(1, symbOSDMDuration/nSymbOSDMTx);  % Adapted filter
delay = mean(grpdelay(ga, 1));
delay = 2*delay + 1;

idxSymb = randi([1,64], nQAMSymbPerOSDMSymb, nSymbOSDMTx);

%% Generation du signal

% Modulation
Sk = qam64_fast_fast(idxSymb, params.maps);

sl_ = zeros(size(carrier.walsh.temporel));
% bloc IDWT
for i=1:nQAMSymbPerOSDMSymb
    idxAvailable           = carrier.available(i);
    coeffs                 = real(carrier.walsh.Xw_b);
    upsampled_symb         = upsample_(Sk(i,:), symbOSDMDuration/nSymbOSDMTx * size(Sk, 2));
    coeffCarrier           = zeros(size(upsampled_symb));
    coeffCarrier(1:2:end)  = 1;
    coeffCarrier(2:2:end)  = 1j;
    coeffs(idxAvailable,:) = real(upsampled_symb.*coeffCarrier);
    sigComputed            = walsh(coeffs, params.W, params.Nfft, params.osr, false);
    sl_                    = sl_ + sigComputed.temporel;
end
sl     = sl_ / nQAMSymbPerOSDMSymb;
Xw_TX  = dwt(sl(1:params.osr:end), params.W, params.order, true); 
Xw_TX_ = dwt(sl_(1:params.osr:end), params.W, params.order, true); 

Sl = abs(fftshift(fft(sl, params.Nfft)));

% Recuperation partie reelle
s         = real(sl);
Xw_TXReal = dwt(s(1:params.osr:end), params.W, params.order, true); 

% Extraction des coeffs + simulation DAC
[sWalsh, XWalsh]    = wse(s, params, length(s));
[nCoeffs, nWindows] = size(XWalsh);
windowsAxis         = 1:nWindows;
coeffsAxis          = 1:nCoeffs;

%% Canal

% Noise power estimation
Psig   = 1/length(sWalsh) * sum(abs(sWalsh).^2);
Pbruit = Psig/SNR;

% Noise
b = sqrt(Pbruit)*randn(size(sWalsh));

y = sWalsh;

% Conformity verification
sigRecFFT = fftshift(fft(sWalsh, params.Nfft));
sigRecPow = abs(sigRecFFT).^2;
sigRecdB  = 10*log10(sigRecPow/max(sigRecPow));

if ~isConform(sigRecdB(nullFrequencyIdx:maxConformFrequency), params.BW_visible(nullFrequencyIdx:maxConformFrequency).')
    nNotConform = nNotConform + 1;
end
%% Recepteur

% Echantillonnage a Te + Synchro : on considere que c'est bon !
% DWT
coeffsReception = dwt(y(1:params.osr:end), params.W, params.order, true);

% DAC : On considere que c'est bon !
coeffsReception = quantification(coeffsReception, params.nBitsAmp, params.max_bin);

% Reconstruction numerique du signal
[sigRx]   = walsh(coeffsReception, params.W, params.Nfft, params.osr, true);
XW_RxReal = dwt(sigRx.temporel(1:params.osr:end), params.W, params.order, true); 

% Generation de la sous-porteuse au niveau du recepteur
carrierCoeffs = dwt(coeffCarrier, params.W, params.order, true);
walshCarrier = walsh(carrierCoeffs, params.W, params.Nfft, params.osr, false);
Wcosine = real(walshCarrier.temporel).';
Wsine = imag(walshCarrier.temporel).';

% Recuperation de l'enveloppe complexe par Hilbert
Xw_TxImag = hilbertWalsh(Xw_TXReal, params.W);

% Generation des signaux I/Q
Xw_TxCI = Xw_TXReal(carrier.available,:) .* Wcosine(1:length(Xw_TXReal)) + Xw_TxImag(carrier.available, :).* Wsine(1:length(Xw_TXReal));
Xw_TxCQ = Xw_TxImag(carrier.available, :).* Wcosine(1:length(Xw_TXReal)) - Xw_TXReal(carrier.available,:).* Wsine(1:length(Xw_TXReal));

% Combinaison des signaux, compensation et extraction des coeffs d'interet
Xw_TxCSymb = (Xw_TxCI + 1j*Xw_TxCQ) * nQAMSymbPerOSDMSymb;
Xw_TxC = coeffs;
Xw_TxC(carrier.available,:) = Xw_TxCSymb;

% Statistiques
threshold = 5e-3;
positionSymbolesI = find(Wcosine > 1-threshold);
positionSymbolesQ = find(Wsine > 1-threshold);

extractedSymbolsI = real(Xw_TxC(carrier.available, positionSymbolesI));
extractedSymbolsQ = imag(Xw_TxC(carrier.available, positionSymbolesQ));
extractedSymbols = zeros(length(carrier.available), nSymbOSDMTx);

currentSymbol = 0;
neighbours = 0;
symbolptr = 1;
i=1;

while i<=length(positionSymbolesI)
    if i == length(positionSymbolesI)
        currentSymbol = currentSymbol + extractedSymbolsI(:,i);
        neighbours = neighbours + 1;
    else
        currentSymbol = currentSymbol + extractedSymbolsI(:,i);
        neighbours = neighbours + 1;
        while i ~= length(positionSymbolesI) && positionSymbolesI(i+1) == positionSymbolesI(i) + 1
            i = i+1;
            currentSymbol = currentSymbol + extractedSymbolsI(:,i);
            neighbours = neighbours + 1;
        end
    end
    currentSymbol = currentSymbol/neighbours;
    extractedSymbols(:,symbolptr) = currentSymbol;
    symbolptr = symbolptr + 1;
    currentSymbol = 0;
    neighbours = 0;
    i = i+1;
end

symbolptr = 1;
i=1;

while i<=length(positionSymbolesQ)
    if i == length(positionSymbolesQ)
        currentSymbol = currentSymbol + extractedSymbolsQ(:,i);
        neighbours = neighbours + 1;
    else
        currentSymbol = currentSymbol + extractedSymbolsQ(:,i);
        neighbours = neighbours + 1;
        while i ~= length(positionSymbolesQ) && positionSymbolesQ(i+1) == positionSymbolesQ(i) + 1
            i = i+1;
            currentSymbol = currentSymbol + extractedSymbolsQ(:,i);
            neighbours = neighbours + 1;
        end
    end
    currentSymbol = currentSymbol/neighbours;
    extractedSymbols(:,symbolptr) = extractedSymbols(:,symbolptr) + 1j * currentSymbol;
    symbolptr = symbolptr + 1;
    currentSymbol = 0;
    neighbours = 0;
    i = i+1;
end

extractedSymbolsPreMean = reshape(extractedSymbols.', nRefreshPerSymbol/2, []);
idxSymbTrsp = idxSymb.';
extractedSymbolsMean = mean(extractedSymbolsPreMean);
symbolsRxIdx = qam64demod(extractedSymbolsMean, params.maps) + 1;
symbolsRxBinary = int2bit(symbolsRxIdx, M, true);
symbolsTxBinary = int2bit(idxSymbTrsp(:).', M, true);
errorsBits = sum(symbolsTxBinary~=symbolsRxBinary, "all");
errorsSymbols = sum(symbolsRxIdx.' ~= idxSymbTrsp(:));

% Analyse frequentielle (pour les plots)
sReal = walsh(Xw_TXReal, params.W, params.Nfft, params.osr, true);
sImag = walsh(Xw_TxImag, params.W, params.Nfft, params.osr, true);
sCplx = walsh(Xw_TxC, params.W, params.Nfft, params.osr, true);


%% AFFICHAGE TEMPOREL

visualizationLength = 24000; % samples
visualizationStart  = 500; % First sample
visualizationEnd    = visualizationStart + visualizationLength - 1;
visualizationTime   = [visualizationStart visualizationEnd]/params.fech;
colorMap            = plotColors();

figure("Name", "Time domain", "Position", figurePos)

subplot(2, 3, 1)
plot((1:length(sl))/params.fech, abs(sl), "DisplayName", "$s_l(t)$", "LineWidth", 3, "Color", "#A2142F");
title("$|s_l(t)|$","Interpreter","latex");
grid on; hold on;
plot((1:length(sl))/params.fech, real(sl), "DisplayName", "$\Re(s_l(t))$", "LineWidth", 3, "Color", "#A2142F", ...
    "LineStyle", "--");
xlim(visualizationTime);
ylim([-10 10]);

subplot(2, 3, 2)
plot((1:length(s))/params.fech, s, "DisplayName", "$s(t)$", "LineWidth", 1.5, "Color", "#D95319");
title("$s(t)$","Interpreter","latex");
grid on;
xlim(visualizationTime);
ylim([-10 10]);

subplot(2, 3, 3)
stairs((1:length(sWalsh))/params.fech, sWalsh, "DisplayName", "$s_{Walsh}(t)$", "LineWidth", 1.5);
title("$s_{Walsh}(t)$","Interpreter","latex");
grid on;
xlim(visualizationTime);
ylim([-10 10]);

subplot(2, 3, 4)
stairs((1:length(y))/params.fech, y, "DisplayName", "$s_{Walsh}(t)$", "LineWidth", 1.5);
title("$y(t)$","Interpreter","latex");
grid on;
xlim(visualizationTime);
ylim([-10 10]);

subplot(2, 3, 5)
plot((1:length(sigRxComplexFiltered))/params.fech, real(sigRxComplexFiltered), "DisplayName", "$\Re(r_l(t))$", ...
    "LineWidth", 1.5, "Color", "#A2142F", "LineStyle", "-.");
grid on; hold on;
plot((1:length(sigRxComplexFiltered))/params.fech, imag(sigRxComplexFiltered), "DisplayName", "$\Re(r_l(t))$", ...
    "LineWidth", 1.5, "Color", "#EDB120", "LineStyle", "-.");
title("$|r_{l,Walsh}(t)|$","Interpreter","latex");
plot((1:fse:length(sl))/params.fech, real(sl(1:fse:end)), "LineStyle", "none", "Marker", "^", "Color", "#A2142F");
plot((1:fse:length(sl))/params.fech, imag(sl(1:fse:end)), "LineStyle", "none", "Marker", "v", "Color", "#EDB120");
xlim(visualizationTime);
ylim([-10 10]);

subplot(2, 3, 6)
stairs((1:length(sigRxComplex))/params.fech, abs(sigRxComplex), "DisplayName", "$|r_l|(t)$", ...
    "LineWidth", 1.5);
grid on; hold on;
plot((1:length(sigRxComplex))/params.fech, real(sigRxComplex), "DisplayName", "$\Re(r_l(t))$", ...
    "LineWidth", 1.5, "Color", "#A2142F", "LineStyle", "--");
title("$|r_l(t)|$","Interpreter","latex");
plot((1:fse:length(sl))/params.fech, abs(sl(1:fse:end)), "LineStyle", "none", "Marker", "v");
plot((1:fse:length(sl))/params.fech, real(sl(1:fse:end)), "LineStyle", "none", "Marker", "^");
xlim(visualizationTime);
ylim([-10 10]);


figure("Name", "Frequency domain", "Position", figurePos)
subplot(2, 3, 1)
plot(freqAxis, abs(fftshift(fft(sl, params.Nfft))), "DisplayName", "$S_l(f)$", "LineWidth", 1.5, "Color", "#A2142F");
title("$S_l(f)$","Interpreter","latex");
grid on;
% xlim([-100e6 100e6]);

subplot(2, 3, 2)
plot(freqAxis, abs(fftshift(fft(s, params.Nfft))), "DisplayName", "$S(f)$", "LineWidth", 1.5, "Color", "#D95319");
title("$S(f)$","Interpreter","latex");
grid on;

subplot(2, 3, 3)
plot(freqAxis, abs(fftshift(fft(sWalsh, params.Nfft))), "DisplayName", "$S_{Walsh}(f)$", "LineWidth", 1.5);
title("$S_{Walsh}(f)$","Interpreter","latex");
grid on;

subplot(2, 3, 4)
plot(freqAxis, abs(fftshift(fft(y, params.Nfft))), "DisplayName", "$S_{Walsh}(f)$", "LineWidth", 1.5);
title("$Y(f)$","Interpreter","latex");
grid on;

subplot(2, 3, 5)
plot(freqAxis, abs(fftshift(fft(sigH, params.Nfft))), "DisplayName", "$R(f)$", "LineWidth", 1.5);
title("$S_H(f)$","Interpreter","latex");
grid on;

subplot(2, 3, 6)
plot(freqAxis, abs(fftshift(fft(sigRxComplex, params.Nfft))), "DisplayName", "$|R_l|(f)$", ...
    "LineWidth", 1.5);
title("$S_a(f)$","Interpreter","latex");
grid on; hold on;
% xlim([-100e6 100e6]);


figure("Name", "Quadratic error", "Position", figurePos)
subplot(1, 2, 1)
plot((1:length(sigRxComplexFiltered(1:fse:end)))/(params.fech/fse), ...
    abs(sigRxComplexFiltered(1:fse:end) - sl(1:fse:end)).^2, "DisplayName", "Complex", "LineWidth", 1.5);
hold on; grid on;
plot((1:length(sigRxComplexFiltered(1:fse:end)))/(params.fech/fse), ...
    abs(real(sigRxComplexFiltered(1:fse:end)) - real(sl(1:fse:end))).^2, "DisplayName", "Real", "LineWidth", 1.5);
plot((1:length(sigRxComplexFiltered(1:fse:end)))/(params.fech/fse), ...
    abs(imag(sigRxComplexFiltered(1:fse:end)) - imag(sl(1:fse:end))).^2, "DisplayName", "Imag", "LineWidth", 1.5);
legend("Interpreter", "latex", "FontSize", 18);
title("Before compensation");
axh          = gca;
axh.FontSize = 18;
axh.YLim     = [0 30];


subplot(1, 2, 2)
plot((1:length(sigRxComplexFiltered(1:fse:end)))/(params.fech/fse), ...
    abs(sigRxComplexFiltered(1:fse:end) - sl(1:fse:end)).^2, "DisplayName", "Complex", "LineWidth", 1.5);
hold on; grid on;
plot((1:length(sigRxComplexFiltered(1:fse:end)))/(params.fech/fse), ...
    abs(real(sigRxComplexFiltered(1:fse:end)) - real(sl(1:fse:end))).^2, "DisplayName", "Real", "LineWidth", 1.5);
plot((1:length(sigRxComplexFiltered(1:fse:end)))/(params.fech/fse), ...
    abs(imag(sigRxComplexFiltered(1:fse:end)) - imag(sl(1:fse:end))).^2, "DisplayName", "Imag", "LineWidth", 1.5);
title("After compensation");
legend("Interpreter", "latex", "FontSize", 18);
axh          = gca;
axh.FontSize = 18;
axh.YLim     = [0 30];

figure("Name", "Conformity spectrum", "Position", figurePos)
plot(params.freq_axis, sigRecdB, "LineWidth", 1.5, "DisplayName", "Sig Tx");
hold on; grid on;
plot(params.freq_axis, params.BW_visible, "LineWidth", 1.5, "DisplayName", "Mask", "LineStyle", "--", ...
    "Color", "#EDB120");
lgh          = legend("Interpreter","latex");
title(lgh, "Legend", "FontSize", 18);
xlim([2.3e9 2.6e9]);
axh          = gca;
axh.FontSize = 18;
ylim([-100 0]);
title("Power spectrum of Tx signal");

carrierFull = analyze(struct("temporel",carrier.temporel), params.Nfft);
symbolsFull = analyze(struct("temporel",sl), params.Nfft);

figure("Name", "Conformity spectrum 2", "Position", figurePos)
subplot(2, 2, 1)
plot(params.freq_axis, carrierFull.dB, "LineWidth", 1.5, "DisplayName", "Carrier");
hold on; grid on;
plot(params.freq_axis, params.BW_visible, "LineWidth", 1.5, "DisplayName", "Mask", "LineStyle", "--", ...
    "Color", "#EDB120");
lgh          = legend("Interpreter","latex");
title(lgh, "Legend", "FontSize", 12);
% xlim([2.3e9 2.6e9]);
axh          = gca;
axh.FontSize = 12;
ylim([-100 0]);
title("Carrier", "Interpreter", "latex");

subplot(2, 2, 2)
plot(params.freq_axis, symbolsFull.dB, "LineWidth", 1.5, "DisplayName", "Symbols baseband");
hold on; grid on;
plot(params.freq_axis, params.BW_visible, "LineWidth", 1.5, "DisplayName", "Mask", "LineStyle", "--", ...
    "Color", "#EDB120");
lgh          = legend("Interpreter","latex");
title(lgh, "Legend", "FontSize", 12);
% xlim([-0.2e9 0.2e9]);
axh          = gca;
axh.FontSize = 12;
ylim([-100 0]);
title("Symbols", "Interpreter", "latex");

subplot(2, 2, 3)
plot(params.freq_axis, carrierFull.dB, "LineWidth", 1.5, "DisplayName", "Carrier");
hold on; grid on;
plot(params.freq_axis, params.BW_visible, "LineWidth", 1.5, "DisplayName", "Mask", "LineStyle", "--", ...
    "Color", "#EDB120");
lgh          = legend("Interpreter","latex");
title(lgh, "Legend", "FontSize", 12);
xlim([2.3e9 2.6e9]);
axh          = gca;
axh.FontSize = 12;
ylim([-100 0]);
title("Carrier close-up", "Interpreter", "latex");

subplot(2, 2, 4)
plot(params.freq_axis, symbolsFull.dB, "LineWidth", 1.5, "DisplayName", "Symbols baseband");
hold on; grid on;
plot(params.freq_axis, params.BW_visible, "LineWidth", 1.5, "DisplayName", "Mask", "LineStyle", "--", ...
    "Color", "#EDB120");
lgh          = legend("Interpreter","latex");
title(lgh, "Legend", "FontSize", 12);
xlim([-0.2e9 0.2e9]);
axh          = gca;
axh.FontSize = 12;
ylim([-100 0]);
title("Symbols close-up", "Interpreter", "latex");

figure("Name", "Symbols comparison", "Position", figurePos)
stem(real(symbolsRx(:)), "DisplayName", "$\Re(S_{k, Rx})$", "LineWidth", 2, "Color", colorMap('blue'));
hold on; grid on;
stem(imag(symbolsRx(:)), "DisplayName", "$\Im(S_{k, Rx})$", "LineWidth", 2, "Color", colorMap('red'));
stem(real(Sk(:)), "DisplayName", "$\Re(S_{k, Tx})$", "LineWidth", 2, "Color", colorMap('blue'), "Marker", "v");
stem(imag(Sk(:)), "DisplayName", "$\Im(S_{k, Tx})$", "LineWidth", 2, "Color", colorMap('red'), "Marker", "v");
legend("Interpreter", "latex", "FontSize", 18);
xlim([1 20]);

figure("Name", "Hilbert test", "Position", figurePos)
plot(params.freq_axis, sReal.spectre, "LineWidth", 1.5, "DisplayName", "Real comp.");
hold on; grid on;
plot(params.freq_axis, sImag.spectre, "LineWidth", 1.5, "DisplayName", "Imaginary comp.");
plot(params.freq_axis, sCplx.spectre, "LineWidth", 1.5, "DisplayName", "Complex");
plot(params.freq_axis, Sl, "LineWidth", 1.5, "DisplayName", "Original");
xlabel("Frequency","Interpreter","latex","FontSize",18);
ylabel("Amplitude","Interpreter","latex","FontSize",18);
axh = gca;
axh.FontSize = 18;
legend("Interpreter","latex","FontSize",18);

figure("Name", "Carrier inspection", "Position", figurePos)
plot(real(coeffCarrier), "DisplayName", "$C_I$", "LineWidth", 1.5);
hold on; grid on;
plot(imag(coeffCarrier), "DisplayName", "$C_Q$", "LineWidth", 1.5);
xlim([1 128]);