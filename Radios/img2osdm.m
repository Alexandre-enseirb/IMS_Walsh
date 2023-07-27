function [sig] = img2osdm(commParams, radioParams, walshParams, scrambler, mappingType, imgfile, datatype)
%IMG2OSDM convertit une image donnee en signal OSDM pour etre transmis par une radio USRP-B210.
%
%   [sig] = img2osdm(commParams, radioParams, walshParams)
%
%   [sig] = img2osdm(commParams, radioParams, walshParams, scrambler, mappingType, imgfile, datatype)


if ~exist("mappingType", "var")
    mappingType="grayscale"; % Mapping par defaut
end

if ~exist("imgfile", "var")
    imgfile = "Data/walsh.png"; % Image par defaut
end

if ~exist("datatype", "var")
    datatype="real"; % Type de donnees a l'envoi
end

if ~ismember(datatype, ["real", "complex"])
    error("Datatype has to be 'real' or 'complex'.");
end

if ~strcmpi(mappingType, "grayscale") && ~strcmpi(mappingType, "qpsk") && ~strcmpi(mappingType, "qam")
    error("Unknown mapping type: %s.\nExpected 'grayscale', 'qpsk' or 'qam'.");
end

%% Parametres OSDM
carrierName="";  % fichier de sauvegarde

targetDs    = walshParams.targetDs; % debit symbole vise, Symboles/s
nSymbOSDMTx = 1; % duree de la conformite en symboles
targetTs    = 1/targetDs; % temps symbole vise, en secondes
Te          = 1/walshParams.fech; % Periode d'echantillonnage associee, en secondes
fse         = ceil(targetTs/Te); % Frequence de surechantillonnage, sans unite

realTs = fse*Te; % Temps symbole en pratique, en secondes
realDs = ceil(1/realTs); % Debit symbole en pratique, en secondes

totalDuration    = nextWalshLength(ceil((nSymbOSDMTx/realDs)*walshParams.fech), walshParams.nCoeffs); % Duree totale d'une trame OSDM en echantillons
symbOSDMDuration = ceil(totalDuration/(walshParams.nCoeffs*walshParams.osr)); % Duree en "rafraichissements" d'un symbole OSDM

nModulatedCoeffsPerOSDMSymb = 3; % Nombre de coefficients modules par symbole OSDM

% Facteur d'attenuation (inutilise)
attenuationFactor = 1;

walshParams.nullFrequencyIdx    = ceil(length(walshParams.freqAxis)/2); % Indice de la frequence nulle sur l'axe
walshParams.maxConformFrequency = find(walshParams.freqAxis > walshParams.fWalsh/2, 1); % Indice de la frequence maximale pour laquelle on souhaite etre conforme
if isempty(walshParams.maxConformFrequency) % S'il n'y a pas de maximum, on le fixe a la plus haute frequence de l'axe
    walshParams.maxConformFrequency = walshParams.Nfft;
end

% Generation des coefficients de la porteuse
carriers = generateWalshCarrierFixedDurationClusterize(walshParams, 100, carrierName, totalDuration, ...
        [walshParams.cluster1Size walshParams.cluster2Size walshParams.cluster3Size]);
carrier = carriers{1}; % Informations relatives a la porteuse (coefficients, allure temporelle...)
cluster = carrier.Clusters{2}; % Cluster 2 de la porteuse (coefficients par periode de rafraichissement)

%% Parametres "generation de combinaisons"
nSymbolsCombinationsPerCoefficientsCombinations = 1024; % Pour un ensemble de coeffs donnes, nombre de combinaisons d'amplitudes a tester
nCoeffsToSelect = nModulatedCoeffsPerOSDMSymb; % Nombre de coefficients a selectionner par combinaison
nCombinationsToGenerate = length(commParams.OSDM.grayscaleValues); % Nombre de combinaisons a generer

% "Porteuse complexe" utilisee si l'amplitude des coefficients modules est complexe
% Permet de faire un filtrage de Hilbert au recepteur
coeffCarrier          = ones(1, symbOSDMDuration);
coeffCarrier(2:2:end) = 1j;

% Indique si on souhaite s'arreter une fois toutes les combinaisons necessaires trouvees
% `false` signifie que l'on veut generer autant de combinaisons que possible
% `true` signifie que l'on veut uniquement le nombre de combinaisons demande
stopAtMax = true;

% Generation de nouvelles combinaisons s'il n'y en a pas de sauvegardees sur le disque
if ~isfile("WalshRadioCombinations.mat")
    [modulatedCoeffsWalsh, uniqueCombinations] = improvedCoefficientsSelectionv2(nCoeffsToSelect, ...
        cluster, ...
        carrier, ...
        nSymbolsCombinationsPerCoefficientsCombinations, ...
        nModulatedCoeffsPerOSDMSymb, ...
        nSymbOSDMTx, ...
        nCombinationsToGenerate, ...
        symbOSDMDuration, ...
        coeffCarrier, ...
        attenuationFactor, ...
        stopAtMax, ...
        walshParams);
    save("WalshRadioCombinations.mat", "modulatedCoeffsWalsh", "uniqueCombinations");
else
    load("WalshRadioCombinations.mat", "modulatedCoeffsWalsh");
end

% Generation du mapping Information - Combinaisons
% Dans le cas present, l'information est l'intensite de chaque pixel, codee en entier non-signe sur 8 bits de (0 a 255)
rng(12);
V2C = initMappingSemantic(commParams.OSDM.grayscaleValues, modulatedCoeffsWalsh);

% Lecture de la source d'information
img = imread(imgfile);
% Conversion en grayscale
I = squeeze(img(:,:,1));

% Generation du signal
% TODO : Allouer le tableau a l'avance pour gagner du temps d'execution
sig = [];
for i=1:numel(I)
    % Recuperation de la combinaison associee au pixel lu
    combination = V2C({[double(I(i))]});
    % Generation du signal avec la combinaison donnee
    sig = [sig; generateSigFromDictionary(combination, carrier.walsh.Xw_b, attenuationFactor, walshParams)];
end

% Ajout du preambule
load("bitSynchro.mat", "bitSynchro");

preambleMod = pskmod(bitSynchro, commParams.ModOrderQPSK, commParams.PhaseOffsetQPSK, "gray", InputType="bit");

sig = [preambleMod.'; sig];

% surechantillonnage et filtrage adapte
sigUpsampled = upsample(sig, commParams.fse);
sigFiltered = conv(sigUpsampled, commParams.g);

sig = sigFiltered;
end
