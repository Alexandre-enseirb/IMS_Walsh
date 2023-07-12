function [params] = getCommParamsForWalsh(type)

rParams = getRadioParams('tx');
wParams = getWalshParams();

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
params.bpi64qam = 6;   % bit par entier pour une mod. 64QAM
params.bpiuint8 = 8;   % bit par entier pour un uint8
params.scramblerBase = 2; % base du scrambler
params.scramblerPolynomial = '1 + x + x^2 + x^4'; % registres du scrambler
params.scramblerInitState = [0 1 0 1];
params.scramblerResetPort = true; % pour reset le scrambler
params.scramblerResetFlag = 1;    % remet les registres du scrambler dans leur etat initial a chaque appel
params.ModOrderQPSK = 4;   % QPSK
params.ModOrder64QAM = 64; % 64-QAM
params.Img.dataToTransmitIntensity = 128*128; % taille image + preambule, en symboles OSDM
params.Img.dataToTransmitQPSK = 128*128*4 + 100; % Taille image binarisee + preambule
params.nSamplesPerSymbOSDM = wParams.nCoeffs; % Nombre d'echantillons par symbole OSDM
params.PhaseOffsetQPSK = pi/4;
params.leftMSB = true;


params.M = 2; % Bits per symbols
params.nFrames = 1000; 
params.fse = 2; % Surechantillonnage a l'emission, pour atteindre le debit symbole souhaite

if strcmpi(type, 'tx')
    params.samplesPerFrame = 2000;
else
    params.samplesPerFrame = 4000;
end

params.symbolsPerFrame = params.samplesPerFrame/params.fse; % Nombre de symboles par frame

nFramesToSendQPSK = ceil(params.Img.dataToTransmitQPSK/params.symbolsPerFrame);
params.nFramesTxQPSK = nFramesToSendQPSK*wParams.osr;

nSamplesToSendOSDM = params.Img.dataToTransmitIntensity * params.nSamplesPerSymbOSDM * wParams.OSDMSymbolDuration;
params.nRadioFramesTxOSDM = ceil(params.fse*nSamplesToSendOSDM/params.samplesPerFrame);


params.samplingFreq = rParams.MasterClockRate/rParams.InterpolationDecimationFactor;
params.sampleDuration = 1/params.samplingFreq;
params.frameDuration = params.samplesPerFrame * params.sampleDuration;
params.symbolRate = params.symbolsPerFrame/params.frameDuration;
params.nBitsTx = params.symbolsPerFrame*params.M;
params.g = rcosdesign(params.roll_off, params.span, params.fse, 'sqrt');

% OSDM-related parameters

params.OSDM.RefreshPerSymbol = 50; % Nombre de rafraichissements necessaires a un symbole OSDM
                                 % Plus on a de rafraichissements, plus on est facilement conforme en
                                 % frequence ("porteuse" plus precise), mais plus on perd en debit.
                                 % Aussi, plus on fait de repetitions, plus on a d'echantillons de notre
                                 % symbole pour faire un codage par repetition
params.OSDM.SymbolsRate = params.samplingFreq/(64*params.OSDM.RefreshPerSymbol*wParams.osr);
params.OSDM.preambleIdx = -10:-1;
params.OSDM.grayscaleValues = 0:255;
params.OSDM.QPSKValues = pskmod([0 1 2 3], params.ModOrderQPSK, params.PhaseOffsetQPSK, "gray");
params.OSDM.QAMValues = qammod(0:63, params.ModOrder64QAM, "gray");
end