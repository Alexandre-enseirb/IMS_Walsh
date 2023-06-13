clear; clc; close all; dbstop if error;

set_path();

%% PARAMETRES OSDM

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

carrierRefs = mean(real(carriers{1}.walsh.Xw_b), 2);

%% SEMANTIQUE

% Creation de la fonction d'embedding
emb = fastTextWordEmbedding;

% Ensemble des mots reconnus par la fonction
words = emb.Vocabulary;
words = words(1:16384);

% Traduction des differents mots en vecteurs dans "l'espace semantique"
V = word2vec(emb, words);

% Affichage
XY = tsne(V);
textscatter(XY, words);

load("Combinations_with_walsh_approach_n53.mat", "modulatedCoeffsWalsh");

V2C = initMappingSemantic(V, modulatedCoeffsWalsh);
C2V = dictionary(V2C.values, V2C.keys);

% inputSentence = input("Please write a sentence: ", "s");
inputSentence = "According to all known laws of aviation, there is no way a bee should be able to fly.";

inputList = strsplit(erasePunctuation(inputSentence), " ");

inputVect = word2vec(emb, inputList);

%% ENCODAGE
sig = [];
for i=1:size(inputVect, 1)
    combination = V2C({inputVect(i,:)});
    sig = [sig; generateSigFromDictionary(combination, carriers{1}.walsh.Xw_b, attenuationFactor, params)];
end

%% CANAL

y = sig;

%% DECODAGE

% ADC
rxCoeffs = dwt(y, params.W, params.order, true);
rxCoeffs = rxCoeffs * attenuationFactor;

% Extraction des coefs d'interet
interestingCoeffs = rxCoeffs(carriers{1}.Clusters{2},:);
interestingCoeffs3D = reshape(interestingCoeffs, cluster2Size, [], size(inputVect, 1));

% Reperage par distance a la reference
means = mean(interestingCoeffs3D, 2);
absmeans = abs(means);
coeffDistance = (repmat(carrierRefs(carriers{1}.Clusters{2}), 1, size(inputVect, 1)) - squeeze(absmeans)).^2;

[sorted, perm] = sort(coeffDistance, 1, "descend");

roundOdd = @(x) 2*floor(x/2) + 1; % source: https://fr.mathworks.com/matlabcentral/answers/45932-round-to-nearest-odd-integer

idxPerWord = perm(1:3,:);
meanValuePerWord = zeros(nQAMSymbPerOSDMSymb, size(inputVect, 1));
for i=1:size(inputVect, 1)
    meanValuePerWord(:, i) = roundOdd(means(idxPerWord(:, i), 1, i));
end

coefficientsPerWord = carriers{1}.Clusters{2}(idxPerWord);
[coefficientsPerWordSorted, perm] = sort(coefficientsPerWord, 1, "ascend");
meanValuePerWordSorted = zeros(size(meanValuePerWord));
for i=1:size(inputVect, 1)
    meanValuePerWordSorted(:,i) = meanValuePerWord(perm(:,i), i);
end

finalCombinations = [coefficientsPerWordSorted.' meanValuePerWordSorted.'];
finalCombinations = reshape(finalCombinations.', nQAMSymbPerOSDMSymb,[]).';

outputWords = strings(1, size(inputVect, 1));
for i=1:size(inputVect, 1)
    lineStart = (i-1)*2+1;
    lineEnd = i*2;
    vector = C2V({finalCombinations(lineStart:lineEnd, :)});
    outputWords(i) = vec2word(emb, vector{1});
end

outputString = strjoin(outputWords(~ismissing(outputWords)), " ");

fprintf("Input: %s\n\nOutput: %s\n", inputSentence, outputString);

%% DISPLAY

figure("Name", "toto", "Position", get(0, "ScreenSize"))
plot((1:length(sig))/params.fech, sig);