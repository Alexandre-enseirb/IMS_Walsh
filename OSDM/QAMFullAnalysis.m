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

nullFrequencyIdx    = ceil(length(params.freq_axis)/2);
maxConformFrequency = find(params.freq_axis > params.fWalsh/2, 1);
if isempty(maxConformFrequency)
    maxConformFrequency = params.Nfft;
end

% Generation porteuses
cluster1Size = 4;
cluster2Sizes = 8:40;
cluster3Sizes = 64-cluster2Sizes-cluster1Size;
nC2Sizes = length(cluster2Sizes);


% Extraction de la 1ere porteuse (les deux sont equivalentes)

nQAMSymbPerOSDMSymb = 3;
nSymbTx             = nQAMSymbPerOSDMSymb*nSymbOSDMTx;
threshold           = 5e-3;

% modulatedCoeffs = carriers{1}.Clusters{2};
% modulatedCoeffs = randsample(modulatedCoeffs, nQAMSymbPerOSDMSymb);


lengthUpsampled       = symbOSDMDuration;

% "Porteuse complexe" des coefficients, pour pouvoir appliquer Hilbert
coeffCarrier          = zeros(1, lengthUpsampled);
coeffCarrier(1:2:end) = 1;
coeffCarrier(2:2:end) = 1j;

% Facteurs d'attenuation
attenuationFactors = 2:2:10;
nAttenuationFactors = length(attenuationFactors);

% Statistiques
BER = NaN * ones(nC2Sizes, max(cluster2Sizes), nAttenuationFactors);
nNotConform = NaN * ones(size(BER));
nRerolls = NaN * ones(size(BER));
nSim = 50;
progressTotal = 3960; % ???
progress = 0;
progress5percent = ceil(0.05*progressTotal);
msgSz = 0;
%% SIMU

SNR = 10^(5/10);


for iC2Size = 1:nC2Sizes

    [carriers, stats] = generateWalshCarrierFixedDurationClusterize(params, 100, carrier_name, totalDuration, ...
        [cluster1Size cluster2Sizes(iC2Size) cluster3Sizes(iC2Size)]);

    carrier = carriers{1};

    for iCoeff=1:cluster2Sizes(iC2Size)
        %fprintf("Size: %d, coeff: %d\n", cluster2Sizes(iC2Size), carrier.Clusters{2}(iCoeff));
        nNotConform(iC2Size, iCoeff, :) = 0;
        nRerolls(iC2Size, iCoeff, :) = 0;
        BER(iC2Size, iCoeff, :) = 0;
        modulatedCoeffs = selectModulationCoefficients(nQAMSymbPerOSDMSymb, carrier.Clusters{2}, params, iCoeff);

        for iAttenuation = 1:nAttenuationFactors
            progress = progress + 1;
            nTransmitted = 0;
            if iAttenuation==1
                carriageReturn = strjoin(repmat("\b", msgSz, 1), "");
                fprintf(carriageReturn);
                msgSz          = fprintf("[%s%s] (%8.4f%%) (%5d/%5d)\n", ...
                    strjoin(repmat("#", floor(progress/progress5percent), 1)), ...
                    strjoin(repmat("-", 20-floor(progress/progress5percent), 1)), ...
                    progress/progressTotal * 100, ...
                    progress, progressTotal);
                drawnow("update");
            end
            for iSim = 1:nSim
                notConform = false;
                nRerollsCurrent = 0;
                [sWalsh, sigRecdB, coeffs, idxSymb] = createSignal(nQAMSymbPerOSDMSymb, nSymbOSDMTx, M, carrier, symbOSDMDuration, modulatedCoeffs, coeffCarrier, attenuationFactors(iAttenuation), params);

                while ~isConform(sigRecdB(nullFrequencyIdx:maxConformFrequency), params.BW_visible(nullFrequencyIdx:maxConformFrequency).') && ~notConform
                    nRerollsCurrent = nRerollsCurrent + 1;
                    nRerolls(iC2Size, iCoeff, iAttenuation) = nRerolls(iC2Size, iCoeff, iAttenuation) + 1;
                    if nRerollsCurrent > 128
                        notConform = true;
                    end
                    [sWalsh, sigRecdB, coeffs, idxSymb] = createSignal(nQAMSymbPerOSDMSymb, nSymbOSDMTx, M, carrier, symbOSDMDuration, modulatedCoeffs, coeffCarrier, attenuationFactors(iAttenuation), params);
                end

                if notConform
                    nNotConform(iC2Size, iCoeff, iAttenuation) = nNotConform(iC2Size, iCoeff, iAttenuation) + 1;

                else


                    % Canal
                    % Noise power estimation
                    Psig   = 1/length(sWalsh) * sum(abs(sWalsh).^2);
                    Pbruit = Psig/SNR;

                    % Noise
                    b = sqrt(Pbruit)*randn(size(sWalsh));

                    y = sWalsh + b;

                    % Rx
                    % DWT
                    coeffsReception = dwt(y(1:params.osr:end) * attenuationFactors(iAttenuation), params.W, params.order, true);

                    % DAC
                    coeffsReception = quantification(coeffsReception, params.nBitsAmp, params.max_bin);

                    % Reconstruction numerique du signal

                    % Generation de la sous-porteuse au niveau du recepteur
                    carrierCoeffs = dwt(coeffCarrier(1,:), params.W, params.order, true);
                    walshCarrier  = walsh(carrierCoeffs, params.W, params.Nfft, params.osr, false);
                    Wcosine       = real(walshCarrier.temporel).';
                    Wsine         = imag(walshCarrier.temporel).';

                    % Extraction de la "partie utile"
                    Wcosine = Wcosine(1:size(coeffsReception, 2));
                    Wsine = Wsine(1:size(coeffsReception, 2));

                    % Recuperation de l'enveloppe complexe par Hilbert
                    Xw_TxImag = hilbertWalsh(coeffsReception, params.W);

                    % Generation des signaux I/Q
                    Xw_TxCI = coeffsReception(modulatedCoeffs,:) .* Wcosine + Xw_TxImag(modulatedCoeffs, :) .* Wsine;
                    Xw_TxCQ = Xw_TxImag(modulatedCoeffs, :) .* Wcosine - coeffsReception(modulatedCoeffs,:) .* Wsine;

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
                    nTransmitted = nTransmitted + 1;
                    BER(iC2Size, iCoeff, iAttenuation) = BER(iC2Size, iCoeff, iAttenuation) + bitErrors;
                end
            end
            if nTransmitted == 0
                BER(iC2Size, iCoeff, iAttenuation) = NaN;
            else
                BER(iC2Size, iCoeff, iAttenuation) = BER(iC2Size, iCoeff, iAttenuation)/(nTransmitted*M*nSymbTx*nSymbOSDMTx);
            end
        end
    end
end

save("sim_qam_5_64_rerolls_test_1_symb.mat");
%% AFFICHAGE
%
% figure("Name", "Spectrum", "Position", figurePos, "Resize", "off")
% plot(params.freq_axis, sigRecdB, "DisplayName", "Semantic signal", "LineWidth", 2);
% hold on; grid on;
% plot(params.freq_axis, params.BW_visible, "DisplayName", "Mask", "LineWidth", 2, "LineStyle", "--");
% xlim([0 4e9]);
% xlabel("Frequency, Hz", "FontSize", 22, "Interpreter", "latex");
% ylabel("Power, dB", "FontSize", 22, "Interpreter", "latex");
% legend("Interpreter", "latex", "FontSize", 22, "Location", "southeast");
% axh = gca;
% axh.FontSize = 22;
% exportgraphics(axh, "visuals/Cluster_2_size_8_spurs.pdf");
%
% figure("Name", "Coeffs", "Position", figurePos, "Resize", "off")
% plot(params.freq_axis, abs(fftshift(fft(params.W(modulatedCoeffs(1),:), params.Nfft))), "DisplayName", string(modulatedCoeffs(1)));
% hold on; grid on;
% plot(params.freq_axis, abs(fftshift(fft(params.W(modulatedCoeffs(2),:), params.Nfft))), "DisplayName", string(modulatedCoeffs(2)));
% plot(params.freq_axis, abs(fftshift(fft(params.W(modulatedCoeffs(3),:), params.Nfft))), "DisplayName", string(modulatedCoeffs(3)));
% legend("Interpreter", "latex", "FontSize", 22)
% axh = gca;
% xlabel("Frequency, Hz", "FontSize", 22, "Interpreter", "latex");
% ylabel("Amplitude", "FontSize", 22, "Interpreter", "latex");
% axh.FontSize = 22;
% exportgraphics(axh, "visuals/Cluster_2_size_8_used_functions.pdf");
%
% figure("Name", "Time domain", "Position", figurePos, "Resize", "off")
% plot((1:length(sWalsh))/params.fech, sWalsh, "DisplayName", "Semantic signal");
% xlim([5e-6 6e-6]); grid on;
% xlabel("Time, s", "FontSize", 22, "Interpreter", "latex");
% ylabel("Amplitude", "FontSize", 22, "Interpreter", "latex");
% legend("Interpreter", "latex", "FontSize", 22);
% axh = gca;
% axh.FontSize=22;
% exportgraphics(axh, "visuals/Cluster_2_size_8_time_domain.pdf");

