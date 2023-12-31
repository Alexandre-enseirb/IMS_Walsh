function [params] = getCommParams(type)

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
params.PhaseOffsetQPSK = pi/4;
params.leftMSB = true;
params.nBERPoints = 3;

params.M = 2; % Bits per symbols
params.nFrames = 1000; 

totalDataToTransmit = 65636; % 65536 symboles QPSK d'image + 100 symboles porteurs

if strcmpi(type, 'tx')
    params.samplesPerFrame = 2000;
else
    params.samplesPerFrame = 4000;
end

params.fse = 10*wParams.osr;
params.symbolsPerFrame = floor(params.samplesPerFrame/params.fse);
requiredSymbolsTx = ceil(totalDataToTransmit/params.symbolsPerFrame);
params.nFramesTx = requiredSymbolsTx*wParams.osr;
params.samplingFreq = rParams.MasterClockRate/rParams.InterpolationDecimationFactor;
params.sampleDuration = 1/params.samplingFreq;
params.frameDuration = params.samplesPerFrame * params.sampleDuration;
params.symbolRate = params.symbolsPerFrame/params.frameDuration;
params.nBitsTx = params.symbolsPerFrame*params.M;
params.g = rcosdesign(params.roll_off, params.span, params.fse, 'sqrt');

% OSDM-related parameters


params.OSDM.RefreshPerSymbol = 10; % Nombre de rafraichissements necessaires a un symbole OSDM
                                 % Plus on a de rafraichissements, plus on est facilement conforme en
                                 % frequence ("porteuse" plus precise), mais plus on perd en debit.
                                 % Aussi, plus on fait de repetitions, plus on a d'echantillons de notre
                                 % symbole pour faire un codage par repetition
params.OSDM.SymbolsRate = params.samplingFreq/(64*params.OSDM.RefreshPerSymbol*wParams.osr);
params.OSDM.grayscaleValues = 0:255;
params.OSDM.QPSKValues = pskmod([0 1 2 3], params.ModOrderQPSK, params.PhaseOffsetQPSK, "gray");
params.OSDM.QAMValues = qammod(0:63, params.ModOrder64QAM, "gray");
end