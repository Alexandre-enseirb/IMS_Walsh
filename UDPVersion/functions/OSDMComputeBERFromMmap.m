%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ce script realise la synchronisation manuelle d'un signal recu module en QPSK.
%
% Le signal recu doit contenir une trame avec les informations d'intensite en niveaux de gris d'une image 128x128
% pixels. Si la trame est plus courte, l'imag esera zero-paddee. Si elle est trop longue, elle sera tronquee.
%
% La synchronisation manuelle se fait en plusieurs etapes :
%
%   - La selection d'un point de depart pour le signal dans l'un des deux buffers du recepteur. Ce point de depart
%   doit etre choisi a moins de 2000 echantillons du preambule pour des resultats optimaux (zoomer et choisir un
%   indice d'echantillon le plus proche possible)
%   - La synchronisation temporelle grossiere : a partir des parametres de surechantillonnage fournis a la radio
%   emetteur, le script propose des constellations pour chaque instant de surechantillonnage, et l'utilisateur
%   choisit l'instant proposant la constellation la plus proche. Cela permet de minimiser l'Interference Entre Symboles
%   (IES)
%   - La synchronisation frequentielle grossiere consiste en une PLL "magique" qui elimine le decalage de phase sur le
%   signal.
%   - La synchronisation temporelle fine utilise le preambule (bitSynchro.mat) pour detecter le debut du signal par
%   une formule d'intercorrelation simplifiee. /!\ En fonction de la facon dont a ete genere bitSynchro.mat, il est
%   possible que ce preambule se retrouve dans le signal, creant un "faux positif" pour la detection du preambule.
%   - La synchronisation frequentielle fine utilise le preambule detecte et le compare au preambule genere via
%   bitSynchro.mat pour calculer le dephasage entre les deux constellations. Ce dephasage doit etre applique lors de la
%   demodulation pour retrouver les symboles originaux.
%
% Enfin, l'image est restauree via une conversion des bits estimes en nouveaux pixels.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [BER, flag, errorsCount, bitsCount, invalidCoeffs] = OSDMComputeBERFromMmap(buffer1, buffer2, commParams, mmap)

%% CHOIX DU DEBUT DU SIGNAL

load("bitSynchro.mat", "bitSynchro");

% Detection du debut du signal
[sig, start, endf, flag] = detectSignalStartEndV2(buffer1);
b=1; % Indique dans le workspace qu'on utilise les donnees du buffer 1 (variable de debug)
if ~flag % Si le signal n'est pas exploitable
    [sig, start, endf, flag] = detectSignalStartEndV2(buffer2);
    b=2; % Indique dans le workspace qu'on utilise les donnees du buffer 2 (variable de debug)
    if ~flag % Si le signal n'est toujours pas exploitable
        BER=-1; flag=true; return; % Pas de BER, et on indique une erreur avec le flag
    else
        noise = [buffer2(1:start) buffer2(endf:end)]; % Extraction du bruit pour le calcul du SNR
    end
else
    noise = [buffer1(1:start) buffer1(endf:end)]; % Extraction du bruit pour le calcul du SNR
end

% Recuperation de memoire
clear buffer1 buffer2

% Calcul de puissance du bruit et du signal
Pbruit = var(noise);

Psig = 1/length(sig)*sum(abs(sig).^2);

Eb = estimateEb(Psig, commParams, radioParams);

SNRLin = Psig/Pbruit;
SNRdB = 10*log10(SNRLin);

%% CHARGEMENT DES PARAMETRES ET SYNCHRONISATION TEMPORELLE GROSSIERE

% Version "ancien recepteur" 
if ~exist("commParams", "var")
    commParams = getCommParamsBER('rx'); % Parametres de la communication
end

walshParams = getWalshParams();

% Chargement des combinaisons utilisees par l'emetteur
load("WalshRadioCombinations.mat", "modulatedCoeffsWalsh", "uniqueCombinations");

% On fixe la RNG, et on genere les dictionnaires de codage/decodage
rng(12);
V2C = initMappingSemantic(commParams.OSDM.grayscaleValues, modulatedCoeffsWalsh);
C2V = dictionary(V2C.values, V2C.keys);

% On recupere aussi les valeurs des coefficients porteurs
[carriers, ~] = generateWalshCarrierFixedDurationClusterize(walshParams, 100, "", walshParams.totalDuration, ...
            [walshParams.cluster1Size walshParams.cluster2Size walshParams.cluster3Size]);
carrier = carriers{1};

%% PREMIERE SYNCHRO TEMPORELLE
% On va se servir du preambule pour la realiser

% Calcul de la duree du preambule
nSymbPreamble = size(bitSynchro, 2);
nSymbPreambleUpsample = nSymbPreamble * commParams.fse;

% Filtrage adapte du signal
sig = conv(sig, commParams.g);

% Modulation du preambule
preambleSymb = pskmod(bitSynchro, commParams.ModOrderQPSK, commParams.PhaseOffsetQPSK, "gray", InputType="bit").';

% Surechantillonnage pour la premiere synchronisation
preambleUpsampled = upsample(preambleSymb, 2);

% Recherche du preambule dans le signal recu par calcul d'intercorrelation
p = intercorr(sig(1:1e6), preambleUpsampled);
[~, idxDebutPreamble] = max(abs(p));
N = length(preambleSymb);

% Estimation de l'instant symbole a partir de la detection du preambule

preambleExtracted = sig(idxDebutPreamble:idxDebutPreamble + commParams.fse * N);
symbolTime = findBestSubSample(preambleExtracted, commParams.fse, N, commParams.ModOrderQPSK);

if mod(idxDebutPreamble, 2) == 0
    symbolTime = symbolTime + 1;
    if symbolTime == commParams.fse + 1
        symbolTime = 1;
    end
end

% Sous-echantillonnage du signal au temps symbole
sigDown = sig(symbolTime:commParams.fse:end);

% Recherche du preambule dans le signal recu par calcul d'intercorrelation
p = intercorr(sigDown(1:1e6), preambleSymb);
[~, midx] = max(abs(p));
N = length(preambleSymb);

% Separation preambule/signal
preambleRx = sigDown(midx:midx+N-1);
sigImg = sigDown(midx+N:end);

% Estimation de l'erreur de phase pour pouvoir projeter le signal sur l'axe des reels
err = 1/N * sum(preambleRx .* conj(preambleSymb)./abs(preambleSymb).^2);
phase_orig = angle(err);

% Rotation du signal vers l'axe des reels
sigRetab = sigImg*exp(-1j*phase_orig);

% On extrait exactement le nombre d'echantillons que l'on souhaite (sinon, erreurs a la transformee de Walsh)
expectedSignalLength = walshParams.nCoeffs * walshParams.OSDMSymbolDuration * commParams.Img.dataToTransmitIntensity;

% Si on a plus d'echantillons que prevu
if length(sigRetab) > expectedSignalLength
    % On rogne la fin du signal (on part du principe que le debut est correctement trouve)
    sigRetab = sigRetab(1:expectedSignalLength);
else
    % Sinon, on pad de zeros
    % Il doit y avoir une methode plus efficace, mais pour l'instant
    % on va se contenter de celle-ci
    tmp = zeros(1, expectedSignalLength);
    tmp(1:length(sigRetab)) = sigRetab;
    sigRetab = tmp;
end

% Projection sur l'axe des reels pour recuperer le signal de Walsh original
amplitudes = real(sigRetab);
carrierRefs = real(carrier.walsh.Xw_b);

% Transformee de Walsh
rxCoeffs = dwt(amplitudes, walshParams.W, walshParams.order, true);

% Extraction des coefs d'interet
interestingCoeffs = rxCoeffs(uniqueCombinations,:);
if mod(size(interestingCoeffs, 2), commParams.Img.dataToTransmitIntensity) ~= 0
    interestingCoeffs = [interestingCoeffs zeros(length(uniqueCombinations), commParams.Img.dataToTransmitIntensity - mod(size(interestingCoeffs, 2), commParams.Img.dataToTransmitIntensity))];
end

% Conversion en 3D (separation par symbole OSDM et par coefficient)
interestingCoeffs3D = reshape(interestingCoeffs, length(uniqueCombinations), [], commParams.Img.dataToTransmitIntensity);

% Calcul du "bruit" des coefficients" (distance a la reference)
noise = interestingCoeffs3D - repmat(carrierRefs(uniqueCombinations, :), 1, 1, size(interestingCoeffs3D, 3));  
meanNoise = squeeze(mean(noise, 2));

% Tri par bruit decroissant. Dans des conditions optimales, les coefficients les plus "bruites" sont ceux modules
[~, perm] = sort(abs(meanNoise), 1, 'descend');
meanValues = mean(interestingCoeffs3D, 2);

% Arrondi a l'impair le plus proche (puisque valeurs = {-1, 1})
roundOdd = @(x) 2*floor(x/2) + 1; % source: https://fr.mathworks.com/matlabcentral/answers/45932-round-to-nearest-odd-integer

% Nombre de symboles a demoduler
nQAMSymbPerOSDMSymb = 3;
% Recuperation de l'indice des coefficients modules
idxPerWord = perm(1:nQAMSymbPerOSDMSymb,:);
% Recuperation de leur valeur moyenne
meanValuePerWord = zeros(nQAMSymbPerOSDMSymb, commParams.Img.dataToTransmitIntensity);

% Arrondi a l'entier impair de toutes les valeurs des coefficients
for i=1:commParams.Img.dataToTransmitIntensity
    meanValuePerWord(:, i) = roundOdd(meanValues(idxPerWord(:, i), 1, i));
end

% Recuperation de l'indice des coefficients parmi les 64 coefficients initiaux
% Cela permet de generer la combinaison telle qu'envoyee par Tx
coefficientsPerWord = uniqueCombinations(idxPerWord);
% On trie les coefficients dans l'ordre croissant
[coefficientsPerWordSorted, perm] = sort(coefficientsPerWord, 1, "ascend");
% Et on leur associe la bonne valeur
meanValuePerWordSorted = zeros(size(meanValuePerWord));
for i=1:commParams.Img.dataToTransmitIntensity
    meanValuePerWordSorted(:,i) = meanValuePerWord(perm(:,i), i);
end

% Enfin, on met en forme la combinaison
finalCombinations = [coefficientsPerWordSorted.' meanValuePerWordSorted.'];
finalCombinations = reshape(finalCombinations.', nQAMSymbPerOSDMSymb,[]).';

% Et on regenere l'image
ImgRx = zeros(1, commParams.Img.dataToTransmitIntensity);
validIdx = logical(ones(1, commParams.Img.dataToTransmitIntensity));
for i=1:commParams.Img.dataToTransmitIntensity
    % Pointeurs sur les deux lignes a lire
    lineStart = (i-1)*2+1;
    lineEnd = i*2;
    % Verifie que la combinaison est bien une cle du dictionnaire
    [canInsert, finalKey] = isAKey(finalCombinations(lineStart:lineEnd, :), C2V.keys);
    if ~canInsert % Sinon, le pixel est ignore, et mis a 0
        fprintf("Skipping idx %d\n", i);
        ImgRxCell = {0};
        validIdx(i) = logical(0);
    else
        ImgRxCell = C2V({finalKey});
    end
    ImgRx(i) = ImgRxCell{1};
end

%% ESTIMATION DU BER
bpi = 8; % Bits par integer (uint8 = 8 bits/int)
leftMSB = true; % Bit de poids fort a gauche

% Conversion de l'image en binaire
ImgRxBinary = int2bit(ImgRx(validIdx).', bpi, leftMSB);

% Lecture de l'image initiale
imgInit = mmap.Data;
imgInitVector = imgInit(validIdx);

imgInitBinary = int2bit(imgInitVector, bpi, leftMSB);
    
errorsCount = sum(abs(ImgRxBinary-double(imgInitBinary)), "all");
bitsCount = sum(validIdx) * bpi;
if sum(validIdx) > 100
    disp("foo");
end
invalidCoeffs = commParams.Img.dataToTransmitIntensity - sum(validIdx);
BER = errorsCount/(sum(validIdx)*bpi) * 100;