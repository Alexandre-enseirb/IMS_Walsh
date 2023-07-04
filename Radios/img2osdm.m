function [carriers] = img2osdm(commParams, radioParams, walshParams, scrambler, mappingType, imgfile)

    if ~exist("mappingType", "var")
        mappingType="grayscale";
    end

    if ~exist("imgfile", "var")
        imgfile = "Data/walsh.png";
    end

    if ~strcmpi(mappingType, "grayscale") && ~strcmpi(mappingType, "qpsk") && ~strcmpi(mappingType, "qam")
        error("Unknown mapping type: %s.\nExpected 'grayscale', 'qpsk' or 'qam'.");
    end

    % Setup OSDM
    carrier_name="";
    M = 2; % pour le moment en QPSK
    
    targetDs    = commParams.OSDM.SymbolsRate;         % Symbols/s
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

    totalDuration    = ceil((nSymbOSDMTx/realDs)*walshParams.fech); % signal duration
    symbOSDMDuration = totalDuration/(walshParams.nCoeffs*walshParams.osr);
    timeAxis         = (1:totalDuration)/walshParams.fech;

    % Generation porteuses
    cluster1Size = 4;
    cluster2Size = 32;
    cluster3Size = 64-cluster2Size-cluster1Size;

    nQAMSymbPerOSDMSymb = 3;
    nSymbTx             = nQAMSymbPerOSDMSymb*nSymbOSDMTx;
    threshold           = 5e-3;

    % Facteurs d'attenuation
    attenuationFactor = 4;

    [carriers, stats] = generateWalshCarrierFixedDurationClusterize(walshParams, 100, carrier_name, totalDuration, ...
            [cluster1Size cluster2Size cluster3Size]);

    carrierRefs = mean(real(carriers{1}.walsh.Xw_b), 2);

    V2C = initMappingSemantic(commParams.OSDM.grayscaleValues, modulatedCoeffsWalsh);
    img = imread(imgfile);