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

function [BER] = getOSDMBER(buffer1, buffer2, commParams)

%% CHOIX DU DEBUT DU SIGNAL

load bitSynchro.mat

[sig, start, endf, flag] = detectSignalStartEnd(buffer1);
if flag
    [sig, start, endf, flag] = detectSignalStartEnd(buffer2);
    if flag
        error("Please redo measures.");
    else
        noise = [buffer2(1:start) buffer2(endf:end)];
    end
else
    noise = [buffer1(1:start) buffer1(endf:end)];
end

Pbruit = var(noise);
Psig = 1/length(sig)*sum(abs(sig).^2);

SNRLin = Psig/Pbruit;
SNRdB = 10*log10(SNRLin);

%% CHARGEMENT DES PARAMETRES ET SYNCHRONISATION TEMPORELLE GROSSIERE

% Version "ancien recepteur" 
if ~exist("commParams", "var")
    commParams = getCommParams('rx'); % Parametres de la communication
end

walshParams = getWalshParams();

load("WalshRadioCombinations.mat");

rng(12);
V2C = initMappingSemantic([commParams.OSDM.preambleIdx commParams.OSDM.grayscaleValues], modulatedCoeffsWalsh);
C2V = dictionary(V2C.values, V2C.keys);

% Generation porteuses
cluster1Size = 4;
cluster2Size = 32;
cluster3Size = 64-cluster2Size-cluster1Size;

[carriers, stats] = generateWalshCarrierFixedDurationClusterize(walshParams, 100, "", walshParams.totalDuration, ...
            [cluster1Size cluster2Size cluster3Size]);
carrier = carriers{1};

sig = conv(sig, commParams.g);

sigDown = sig(1:2:end);

preambleSymb = pskmod(bitSynchro, commParams.ModOrderQPSK, commParams.PhaseOffsetQPSK, "gray", InputType="bit").';

p = intercorr(sigDown(1:1e6), preambleSymb);
[mval, midx] = max(abs(p));
N = length(preambleSymb);

clear buffer1 buffer2
preambleRx = sigDown(midx:midx+N-1);
sigImg = sigDown(midx+N:end);

err = 1/N * sum(preambleRx .* conj(preambleSymb)./abs(preambleSymb).^2);
phase_orig = angle(err);

sigRetab = sigImg*exp(-1j*phase_orig);

% Projection sur l'axe des reels pour recuperer le signal de Walsh original
amplitudes = real(sigRetab);
carrierRefs = real(carrier.walsh.Xw_b);
% Transformee de Walsh
dureePremierSymboleOSDM = 13*64; % echantillons
rxCoeffs = zeros(64, 13, 64);
targetCoeffs = [32 48 57];
rxCoeffs = dwt(amplitudes, walshParams.W, walshParams.order, true);
% Extraction des coefs d'interet
interestingCoeffs = rxCoeffs(carrier.Clusters{2},:);
if mod(size(interestingCoeffs, 2), commParams.Img.dataToTransmitIntensity) ~= 0
    interestingCoeffs = [interestingCoeffs zeros(length(carrier.Clusters{2}), commParams.Img.dataToTransmitIntensity - mod(size(interestingCoeffs, 2), commParams.Img.dataToTransmitIntensity))];
end
interestingCoeffs3D = reshape(interestingCoeffs, cluster2Size, [], commParams.Img.dataToTransmitIntensity);
noise = interestingCoeffs3D - repmat(carrierRefs(carrier.Clusters{2}, :), 1, 1, size(interestingCoeffs3D, 3));  
meanNoise = squeeze(mean(noise, 2));
[sorted, perm] = sort(abs(meanNoise), 1, 'descend');
meanValues = mean(interestingCoeffs3D, 2);
% Reperage par distance a la reference

roundOdd = @(x) 2*floor(x/2) + 1; % source: https://fr.mathworks.com/matlabcentral/answers/45932-round-to-nearest-odd-integer
nQAMSymbPerOSDMSymb = 3;
idxPerWord = perm(1:3,:);
meanValuePerWord = zeros(nQAMSymbPerOSDMSymb, commParams.Img.dataToTransmitIntensity);
for i=1:commParams.Img.dataToTransmitIntensity
    meanValuePerWord(:, i) = roundOdd(meanValues(idxPerWord(:, i), 1, i));
end
coefficientsPerWord = carrier.Clusters{2}(idxPerWord);
[coefficientsPerWordSorted, perm] = sort(coefficientsPerWord, 1, "ascend");
meanValuePerWordSorted = zeros(size(meanValuePerWord));
for i=1:commParams.Img.dataToTransmitIntensity
    meanValuePerWordSorted(:,i) = meanValuePerWord(perm(:,i), i);
end

finalCombinations = [coefficientsPerWordSorted.' meanValuePerWordSorted.'];
finalCombinations = reshape(finalCombinations.', nQAMSymbPerOSDMSymb,[]).';

cmb = [32 48 57; -1 1 -1];
extract = interestingCoeffs3D(:,:,1);

ImgRx = zeros(1, commParams.Img.dataToTransmitIntensity);
for i=1:commParams.Img.dataToTransmitIntensity
    lineStart = (i-1)*2+1;
    lineEnd = i*2;
    [canInsert, finalKey] = isAKey(finalCombinations(lineStart:lineEnd, :), C2V.keys);
    if ~canInsert
        fprintf("Skipping idx %d\n", i);
        ImgRxCell = {0};
    else
        ImgRxCell = C2V({finalKey});
    end
    ImgRx(i) = ImgRxCell{1};
end
bpi = 8;
leftMSB = true;

ImgRxBinary = int2bit(ImgRx(:), bpi, leftMSB);

imgOg = imread("Data/walsh.png");
imgOg = squeeze(imgOg(:,:,1));
imgOgV = imgOg(:);

imgOgBinary = int2bit(imgOgV, bpi, leftMSB);
    
bitError = sum(abs(ImgRxBinary-double(imgOgBinary)), "all");
BER = bitError/(numel(imgOgV)*bpi) * 100;