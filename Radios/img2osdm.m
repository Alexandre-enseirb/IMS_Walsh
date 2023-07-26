function [sig] = img2osdm(commParams, radioParams, walshParams, scrambler, mappingType, imgfile, datatype)

    if ~exist("mappingType", "var")
        mappingType="grayscale";
    end

    if ~exist("imgfile", "var")
        imgfile = "Data/walsh.png";
    end

    if ~exist("datatype", "var")
        datatype="real";
    end

    if ~ismember(datatype, ["real", "complex"])
        error("Datatype has to be 'real' or 'complex'.");
    end

    if ~strcmpi(mappingType, "grayscale") && ~strcmpi(mappingType, "qpsk") && ~strcmpi(mappingType, "qam")
        error("Unknown mapping type: %s.\nExpected 'grayscale', 'qpsk' or 'qam'.");
    end

    % Setup OSDM
    carrier_name="";
    M = 2; % pour le moment en QPSK
    
    targetDs    = walshParams.targetDs;         % Symbols/s
    nSymbOSDMTx = 1;           % symbols per frame
    targetTs    = 1/targetDs;          % s
    Te          = 1/walshParams.fech; % s
    fse         = ceil(targetTs/Te);   % no unit

    nRefreshPerSymbol = fse/64;
    if mod(nRefreshPerSymbol, 2) == 1 % Compensation des cas impairs
        nRefreshPerSymbol = nRefreshPerSymbol + 1;
        fse               = fse+64;
    end

    realTs           = fse*Te;
    realDs           = ceil(1/realTs);
    channelFrequency = 500e6;

    totalDuration    = nextWalshLength(ceil((nSymbOSDMTx/realDs)*walshParams.fech), walshParams.nCoeffs); % signal duration
    symbOSDMDuration = ceil(totalDuration/(walshParams.nCoeffs*walshParams.osr));
    timeAxis         = (1:totalDuration)/walshParams.fech;

    % Generation porteuses
    cluster1Size = 4;
    cluster2Size = 32;
    cluster3Size = 64-cluster2Size-cluster1Size;

    nQAMSymbPerOSDMSymb = 3;
    nSymbTx             = nQAMSymbPerOSDMSymb*nSymbOSDMTx;
    threshold           = 5e-3;

   


    % Facteurs d'attenuation
    attenuationFactor = 1;

    walshParams.nullFrequencyIdx    = ceil(length(walshParams.freqAxis)/2);
    walshParams.maxConformFrequency = find(walshParams.freqAxis > walshParams.fWalsh/2, 1);
    if isempty(walshParams.maxConformFrequency)
        walshParams.maxConformFrequency = walshParams.Nfft;
    end

    [carriers, stats] = generateWalshCarrierFixedDurationClusterize(walshParams, 100, carrier_name, totalDuration, ...
            [cluster1Size cluster2Size cluster3Size]);

    % Parametres "recherche de combinaisons"
    carrier = carriers{1};
    if strcmpi(datatype, "real")
        carrierRefs = mean(real(carrier.walsh.Xw_b), 2);
    else
        carrierRefs = mean(carrier.walsh.Xw_b, 2);
    end
    cluster = carrier.Clusters{2};
    nSymbolsCombinationsPerCoefficientsCombinations = 1024;
    nCoeffsToSelect = 3;
    nCombinationsToGenerate = length(commParams.OSDM.grayscaleValues);
    
    coeffCarrier          = ones(1, symbOSDMDuration);
    coeffCarrier(2:2:end) = 1j;

    stopAtMax = true;

    if ~isfile("WalshRadioCombinations.mat")
        modulatedCoeffsWalsh = improvedCoefficientsSelectionv2(nCoeffsToSelect, ...
            cluster, ...
            carrier, ...
            nSymbolsCombinationsPerCoefficientsCombinations, ...
            nQAMSymbPerOSDMSymb, ...
            nSymbOSDMTx, ...
            nCombinationsToGenerate, ...
            symbOSDMDuration, ...
            coeffCarrier, ...
            attenuationFactor, ...
            stopAtMax, ...
            walshParams);
        save("WalshRadioCombinations.mat", "modulatedCoeffsWalsh");
    else
        load("WalshRadioCombinations.mat", "modulatedCoeffsWalsh");
    end
    rng(12);
    V2C = initMappingSemantic(commParams.OSDM.grayscaleValues, modulatedCoeffsWalsh);
    C2V = dictionary(V2C.values, V2C.keys);

    img = imread(imgfile);

    I = squeeze(img(:,:,1));
   
    sig = [];
    for i=1:numel(I)
        combination = V2C({[double(I(i))]});
        sig = [sig; generateSigFromDictionary(combination, carrier.walsh.Xw_b, attenuationFactor, walshParams)];
    end
    
    % Ajout du preambule
    load bitSynchro.mat

    preambleMod = pskmod(bitSynchro, commParams.ModOrderQPSK, commParams.PhaseOffsetQPSK, "gray", InputType="bit");
    
    sig = [preambleMod.'; sig];
    % surechantillonnage et filtrage adapte
    sig = upsample(sig, commParams.fse);
    sig = conv(sig, commParams.g);

end

