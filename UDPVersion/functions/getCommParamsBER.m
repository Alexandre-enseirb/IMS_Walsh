function [params] = getCommParamsBER(type)

    radioParams = getRadioParams('tx');
    walshParams = getWalshParams();
    
    params = struct();
    
    % Predefinition
    params.M = 0;
    params.nFrames = 0;
    params.nFramesTx = 0;
    params.symbolsPerFrame = 0;
    params.samplesPerFrame = 0;
    params.samplingFreq = 0;
    params.fse = 0;
    params.sampleDuration = 0;
    params.frameDuration = 0;
    params.symbolRate = 0;
    params.nBitsTx = 0;    
    params.roll_off = 0.5; % roll-off du filtre rcos
    params.span = 5;       % longueur du filtre rcos
    params.bpiqpsk = 2;    % bit par entier pour une mod. QPSK
    params.bpiuint8 = 8;   % bit par entier pour un uint8
    params.ModOrderQPSK = 4;   % QPSK
    params.PhaseOffsetQPSK = pi/4;
    params.leftMSB = true;
    params.Img.dataToTransmitIntensity = 128*128; % taille image + preambule, en symboles OSDM
    params.Img.dataToTransmitQPSK = 128*128*4 + 100; % Taille image binarisee + preambule
    params.Img.dataToTransmitOSDMIntensity = 128*128 + 100; % Nombre de pixels dans l'image + preambule
    params.Img.dataToTransmitOSDM2x2Mapping = 64*64 + 100; % Nombre de pixels dans l'image + preambule
    params.nErrorsMinimum = 100;
    params.nBitsMinimum = 1e6;
    params.bitPerOSDMSymb = 8;
    params.nBERPoints = 1;
    
    % Parametres OSDM
    params.OSDM.RefreshPerSymbol = 13; % Nombre de repetitions d'un meme symbole
    params.OSDM.SymbolsRate = params.samplingFreq/(64*params.OSDM.RefreshPerSymbol*walshParams.osr); % Debit symbole OSDM
    params.OSDM.grayscaleValues = 0:255; % Valeurs d'intensite pour un mapping en grayscale
    %params.OSDM.img2x2Values = load("walsh_2x2_png.mat"); % Valeurs de chaque carre de 2x2 pixels de l'image
    params.OSDM.QPSKValues = pskmod([0 1 2 3], params.ModOrderQPSK, params.PhaseOffsetQPSK, "gray"); % Valeurs des symboles QPSK utilisables

    params.samplesPerOSDMSymbol = walshParams.nCoeffs * params.OSDM.RefreshPerSymbol;
    params.M = 2; % Bits per symbols
    params.nFrames = 1000; 
    
    % totalDataToTransmit = 65636; % 65536 symboles QPSK d'image + 100 symboles porteurs
    
    if strcmpi(type, 'tx')
        params.samplesPerFrame = 2000;
    else
        params.samplesPerFrame = 4000;
    end
    
    params.fse = 2; % frequence de surechantillonnage
    params.symbolsPerFrame = floor(params.samplesPerFrame/(params.fse*params.samplesPerOSDMSymbol)); % nombre de symboles par frame radio
    
    nSamplesToSendOSDM = params.Img.dataToTransmitIntensity * params.nSamplesPerSymbOSDM * wParams.OSDMSymbolDuration;
    params.nRadioFramesTxOSDM = ceil(params.fse*nSamplesToSendOSDM/params.samplesPerFrame);
    dataQuantity = params.Img.dataToTransmitOSDMIntensity; % Type de mapping utilise. Changer cette variable pour modifier le mapping
    
    requiredFramesTx = ceil(dataQuantity/params.symbolsPerFrame); % Nombre de frames radio a emettre
    params.nFramesTx = requiredFramesTx*walshParams.osr; % Redondant, utile si on veut reduire la frequence de Walsh, ce qui n'est pas le cas pour le moment
    params.samplingFreq = radioParams.MasterClockRate/radioParams.InterpolationDecimationFactor; % Frequence d'echantillonnage de la radio
    params.sampleDuration = 1/params.samplingFreq; % Duree d'un echantillon en secondes
    params.frameDuration = params.samplesPerFrame * params.sampleDuration; % duree d'une frame radio en secondes
    params.symbolRate = params.symbolsPerFrame/params.frameDuration; % nombre de symboles emis par seconde
    params.nBitsTx = params.symbolsPerFrame*params.M; % Nombre de bits envoyes par frame radio
    params.g = rcosdesign(params.roll_off, params.span, params.fse, 'sqrt'); % Filtre de mise en forme
    
end