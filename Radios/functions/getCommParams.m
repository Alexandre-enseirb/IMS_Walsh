function [params] = getCommParams(type)

rParams = getRadioParams('tx');

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
params.ModOrderQPSK = 4;   % QPSK
params.ModOrder64QAM = 64; % 64-QAM
params.PhaseOffsetQPSK = pi/4;
params.leftMSB = true;


params.M = 2; % Bits per symbols
params.nFrames = 1000; 

if strcmpi(type, 'tx')
    params.symbolsPerFrame = 500;
    params.samplesPerFrame = 2000;
    params.nFramesTx = 8*165;
else
    params.symbolsPerFrame = 1000;
    params.samplesPerFrame = 4000;
    params.nFramesTx = 4*165;
end
params.samplingFreq = rParams.MasterClockRate/rParams.InterpolationDecimationFactor;
params.fse = params.samplesPerFrame/params.symbolsPerFrame;
params.sampleDuration = 1/params.samplingFreq;
params.frameDuration = params.samplesPerFrame * params.sampleDuration;
params.symbolRate = params.symbolsPerFrame/params.frameDuration;
params.nBitsTx = params.symbolsPerFrame*params.M;
params.g = rcosdesign(params.roll_off, params.span, params.fse, 'sqrt');
%params.g = rectwin(params.fse);
end