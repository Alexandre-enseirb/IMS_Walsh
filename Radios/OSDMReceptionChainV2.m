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

clear; clc; close all; dbstop if error;

setPath();

%% CHOIX DU DEBUT DU SIGNAL

load("bitSynchro.mat", "bitSynchro");
file = "OSDM_img_rx_clock_pps_rrc_Complex_preamble_QPSK.mat";

load(file, "buffer1", "buffer2", "commParams");

[sig, start, endf, flag] = detectSignalStartEndV2(buffer1);
b=1;
if ~flag
    disp("Looking at buffer 2");
    b=2;
    [sig, start, endf, flag] = detectSignalStartEndV2(buffer2);
    if ~flag
        error("Please redo measures.");
    else
        noise = [buffer2(1:start) buffer2(endf:end)];
    end
else
    noise = [buffer1(1:start) buffer1(endf:end)];
end
walshParams = getWalshParams();
Pbruit = var(noise);
Psig = 1/length(sig)*sum(abs(sig).^2);

sigFFT = fftshift(fft(sig, walshParams.Nfft));
sigPow = abs(sigFFT).^2;
sigdBW = 10*log10(abs(sigFFT).^2);
sigdBm = sigdBW + 30;
sigdB = 10*log10(sigPow/max(sigPow));

realFreqIdxStart = find(walshParams.freqAxis > 0, 1);
bwIdxStart = find(walshParams.freqAxis>walshParams.BW.usedInterval(1), 1);
bwIdxEnd = find(walshParams.freqAxis>walshParams.BW.usedInterval(2), 1);
inBandPowerdBm = sigdBm(bwIdxStart:bwIdxEnd);
oobPowerdBm = [sigdBm(realFreqIdxStart:bwIdxStart); sigdBm(bwIdxEnd:end)];
inBandAxis = walshParams.freqAxis(bwIdxStart:bwIdxEnd);
oobAxis = [walshParams.freqAxis(realFreqIdxStart:bwIdxStart) walshParams.freqAxis(bwIdxEnd:end)];

SNRLin = Psig/Pbruit;
SNRdB = 10*log10(SNRLin);

% Affichage des parties reelles et imaginaires des deux buffers.
% Cette etape permet aussi de verifier qu'il n'y a pas eu saturation de l'ADC au recepteur
% (amplitude du signal egale a 1), et d'ajuster en consequence le gain du recepteur.
% figure();
% subplot(2, 2, 1)
% plot(real(buffer1(:)));
% title("RealB1");
%
% subplot(2, 2, 2)
% plot(real(buffer2(:)));
% title("RealB2");
% 
% subplot(2,2,3)
% plot(imag(buffer1(:)));
% title("ImB1");
% 
% subplot(2,2,4)
% plot(imag(buffer2(:)));
% title("ImB2");

%%
% close all; % Fermeture du premier plot

% startIdx = 5271260; % A REMPLACER PAR LA VALEUR LUE DANS LA PREMIERE "PARTIE"
% 
% sig = buffer2;
% sig = sig(startIdx:19137100);

%% CHARGEMENT DES PARAMETRES ET SYNCHRONISATION TEMPORELLE GROSSIERE

% Version "ancien recepteur" 
if ~exist("commParams", "var")
    commParams = getCommParams('rx'); % Parametres de la communication
end



load("WalshRadioCombinations.mat", "modulatedCoeffsWalsh", "uniqueCombinations");

rng(12);
V2C = initMappingSemantic(commParams.OSDM.grayscaleValues, modulatedCoeffsWalsh);
C2V = dictionary(V2C.values, V2C.keys);

% Generation porteuses
cluster1Size = 4;
cluster2Size = 32;
cluster3Size = 64-cluster2Size-cluster1Size;

[carriers, stats] = generateWalshCarrierFixedDurationClusterize(walshParams, 100, "", walshParams.totalDuration, ...
            [cluster1Size cluster2Size cluster3Size]);
carrier = carriers{1};

sigFiltered = conv(sig, commParams.g);
delay = 10;

preambleExtracted = sigFiltered(delay+1:1e6);


% sig = conv(sig, commParams.g);
% 
% sigDown = sig(1:2:end);
% sigDown = sig;
nQAMSymbPerOSDMSymb = 3; % Nombre de coefficients modules par symbole OSDM

preambleSymb = pskmod(bitSynchro, commParams.ModOrderQPSK, commParams.PhaseOffsetQPSK, "gray", InputType="bit").';


symbolTime = findBestSubSample( preambleExtracted, commParams.fse, length(preambleSymb), commParams.ModOrderQPSK, commParams.PhaseOffsetQPSK);
sigDownsampled = sigFiltered(symbolTime+delay:commParams.fse:end-delay);
preambleDownsampled = sigDownsampled(1:1e5);


p = intercorr(preambleDownsampled, preambleSymb);
[mval, midx] = max(abs(p));
N = length(preambleSymb);


clear buffer1 buffer2
preambleRx = sigDownsampled(midx:midx+N-1);
sigImg = sigDownsampled(midx+N:end);

err = 1/N * sum(preambleRx .* conj(preambleSymb)./abs(preambleSymb).^2);
phase_orig = angle(err);

sigRetab = sigImg*exp(-1j*phase_orig);

% Projection sur l'axe des reels pour recuperer le signal de Walsh original
amplitudes = real(sigRetab); % amplitudes recues
tmpMaximalDurationAllowed = 64*13*16384;
amplitudes = amplitudes(1:tmpMaximalDurationAllowed);
carrierRefs = real(carrier.walsh.Xw_b); % valeurs de reference pour les coefficients non-modules

% Transformee de Walsh
rxCoeffs = dwt(amplitudes, walshParams.W, walshParams.order, true);


% Extraction des coefs d'interet
interestingCoeffs = rxCoeffs(uniqueCombinations,:);

% Padding si on n'atteint pas la longueur de l'image
if mod(size(interestingCoeffs, 2), commParams.Img.dataToTransmitIntensity) ~= 0
    interestingCoeffs = [interestingCoeffs zeros(length(uniqueCombinations), commParams.Img.dataToTransmitIntensity - mod(size(interestingCoeffs, 2), commParams.Img.dataToTransmitIntensity))];
end

% Pre-detection des coefficients modules
% Separation des coefficients d'interet par pixel de l'image
interestingCoeffs3D = reshape(interestingCoeffs, length(uniqueCombinations), [], ... 
    commParams.Img.dataToTransmitIntensity);

% Calcul du "bruit" par fenetre de rafraichissement en soustrayant la valeur de reference
noise = interestingCoeffs3D - repmat(carrierRefs(uniqueCombinations, :), 1, 1, size(interestingCoeffs3D, 3));  
meanNoise = squeeze(mean(noise, 2));

% Tri par bruit decroissant
% Les coefficients modules etant "presque partout"™ differents de leur reference
% Ils auront en moyenne un bruit residuel superieur
[sorted, perm] = sort(abs(meanNoise), 1, 'descend');
meanValues = mean(interestingCoeffs3D, 2);

% Arrondi a l'impair le plus proche
% Utile seulement si on utilise des amplitudes impaires
% En l'occurence, seuls 1 et -1 sont utilises
roundOdd = @(x) 2*floor(x/2) + 1; % source: https://fr.mathworks.com/matlabcentral/answers/45932-round-to-nearest-odd-integer

% Extraction des coefficients modules
modulatedCoeffsIdx = perm(1:nQAMSymbPerOSDMSymb,:);
meanValuePerModulatedCoeff = zeros(nQAMSymbPerOSDMSymb, commParams.Img.dataToTransmitIntensity);

% Calcul de leur valeur moyenne, arrondie a l'impair le plus proche
for i=1:commParams.Img.dataToTransmitIntensity
    meanValuePerModulatedCoeff(:, i) = roundOdd(meanValues(modulatedCoeffsIdx(:, i), 1, i));
end

% Recuperation de l'index des coefficients dans notre base de Walsh
modulatedCoeffsWalshIdx = uniqueCombinations(modulatedCoeffsIdx);
% Tri par sequence croissante des coefficients et de leurs amplitudes
[modulatedCoeffsWalshIdxSorted, perm] = sort(modulatedCoeffsWalshIdx, 1, "ascend");
meanValuePerModulatedCoeffSorted = zeros(size(meanValuePerModulatedCoeff));
for i=1:commParams.Img.dataToTransmitIntensity
    meanValuePerModulatedCoeffSorted(:,i) = meanValuePerModulatedCoeff(perm(:,i), i);
end

% Mise en forme de la combinaison coeffs + amplitudes
finalCombinations = [modulatedCoeffsWalshIdxSorted.' meanValuePerModulatedCoeffSorted.'];
finalCombinations = reshape(finalCombinations.', nQAMSymbPerOSDMSymb,[]).';

% Reconstruction de l'image
ImgRx = zeros(1, commParams.Img.dataToTransmitIntensity);
for i=1:commParams.Img.dataToTransmitIntensity
    lineStart = (i-1)*2+1;
    lineEnd = i*2;
    % Verification que la combinaison existe bel et bien
    [canInsert, finalKey] = isAKey(finalCombinations(lineStart:lineEnd, :), C2V.keys);
    if ~canInsert % Si la combinaison n'existe pas, on la skip pour le moment
        fprintf("Skipping idx %d\n", i);
        ImgRxCell = {0};
    else % Sinon, on ajoute son amplitude a notre image
        ImgRxCell = C2V({finalKey});
    end
    ImgRx(i) = ImgRxCell{1};
end

% Reshape et affichage
ImgRx = reshape(ImgRx, 128, 128);

figure
imshow(uint8(ImgRx));

% Comparaison avec l'image originale et calcul de l'erreur quadratique par pixel
ogImg = imread("Data/walsh.png");
ogImgGrayscale = squeeze(ogImg(:,:,1));

quadraticError = (uint8(ogImgGrayscale) - uint8(ImgRx)).^2;

figure
imagesc(quadraticError);
colormap gray; colorbar;
axis square;