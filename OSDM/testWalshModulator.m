clear; clc; close all; dbstop if error;

set_path(); plotSetup();

%%
rng(12);
params = genParamsOSDM(2.4825e9, ...
    2.495e9, ...
    10e6, ...
    1e9, ...
    8e9, ...
    250e6, ...
    6, ...
    14, ...
    8, ...
    false, ...
    8e9, ...
    8e9, ...
    400);

M            = 6; % 64-QAM, 6 bits par symbole
carrier_name = sprintf("data/walsh_carrier_%d@%d_Hz_fd.mat", params.BW_middle_freq, params.fech);

figurePos = getFigPosition(); % Position and size of plots

nCarrierCoeffs = 12; % Nombre de coefficients jouant dans la "porteuse"

SNRdBMin  = -15;          % Signal-to-noise Ratio (dB)
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
cluster2Size = 32;
cluster3Size = 64-cluster2Size-cluster1Size;


% Extraction de la 1ere porteuse (les deux sont equivalentes)

nQAMSymbPerOSDMSymb = 3;
nSymbTx             = nQAMSymbPerOSDMSymb*nSymbOSDMTx;
threshold           = 5e-3;

lengthUpsampled = symbOSDMDuration;


% Facteurs d'attenuation
attenuationFactor = 4;

[carriers, stats] = generateWalshCarrierFixedDurationClusterize(params, 100, carrier_name, totalDuration, ...
        [cluster1Size cluster2Size cluster3Size]);

load("Combinations_with_sum_approach_n53.mat", "modulatedCoeffsSum");
load("Combinations_with_walsh_approach_n53.mat", "modulatedCoeffsWalsh");

combinations = modulatedCoeffsWalsh;

% Valeurs de reference des coefficients "porteurs" moyennee
carrierReference = mean(real(carriers{1}.walsh.Xw_b(carriers{1}.Clusters{2}, :)), 2);

Modulator = walshModulator(carriers{1}.walsh.Xw_b, combinations, attenuationFactor, nQAMSymbPerOSDMSymb);

invModulatedcoeffs = dictionary(combinations.values, combinations.keys);
[mapping, probas] = initMappingProbabilistic(combinations);
invmapping = dictionary(mapping.values, mapping.keys);

usedCoefficients = dictionary(mapping.values, modulatedCoeffsWalsh(mapping.values));
invUsedCoefficients = dictionary(usedCoefficients.values, usedCoefficients.keys);

Decoder = walshDecoder(carriers{1}.walsh.Xw_b, invUsedCoefficients, carrierReference);

%% test
!touch Continue
fh = figure("Name", "Spectrum", "Position", figurePos);
plot(0);
axh = gca;
SNR = 10^(5/10); % 5 dB

while isfile("Continue")
    clc;
    inputSentence = input("Please write your sentence: ", "s");
    % inputSentence = "interview brewed be realm cars future tunes navigated by glinting concrete melodious blossoms";
    if inputSentence=="quit"
        fprintf("Goodbye.\n");
        break;
    end

    idx = translateSentence(inputSentence, mapping);

    nWords = length(idx);

    % Encodage
    
    sig = zeros(nWords * fse, 1);
    words = 0;
    for i=1:length(idx)
        words = words + 1;
        idxStart = (i-1)*fse+1;
        idxEnd = i*fse;
        sig(idxStart:idxEnd) = Modulator.generate(idx(i), params);
    end
    fprintf("%d words\n", words);

    % Canal - pour l'instant sans bruit
    Psig   = 1/length(sig) * sum(abs(sig).^2);
    Pbruit = Psig/SNR;
    
    % Noise
    b = sqrt(Pbruit)*randn(size(sig));

    y = sig + b;

    % Decodage
    
    rxSigCoeffs = dwt(y, params.W, params.order, true);
    newSentence = strings(1, nWords);
    for iWords=1:nWords
        idxStart = (iWords-1)*symbOSDMDuration+1;
        idxEnd = iWords*symbOSDMDuration;
        estimatedIdx = Decoder.decode(rxSigCoeffs(:, idxStart:idxEnd), carriers{1}.Clusters{1,2});
        if estimatedIdx ~= -1
            newSentence(iWords) = translateIdx(estimatedIdx, invmapping);
        else
            newSentence(iWords) = "ERROR";
        end
    end
    
    sigFull = analyze(struct("temporel", sig), params.Nfft);
    
    hold(axh, "off");
    plot(axh, params.freq_axis, sigFull.dB);
    hold(axh,"on"); 
    grid(axh, "on");
    plot(axh, params.freq_axis, params.BW_visible, "LineStyle", "--", "Color", "#EDB120");
    xlim(axh, [0 4e9]);
    ylim(axh, [-100 0]);

    sentence = translateIdx(idx, invmapping);
    fprintf("%s vs. %s\n", sentence, strjoin(newSentence, " "));

    % save(sprintf("%s.mat", sentence), "sigFull");

    pause(5);
end