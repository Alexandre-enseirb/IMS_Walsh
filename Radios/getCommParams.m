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
params.roll_off = 0.5;
params.span = 16;
params.sps = 10;


params.M = 2; % Bits per symbols
params.nFrames = 1000; 

params.symbolsPerFrame = 100;
if strcmp(type, 'tx')
    params.samplesPerFrame = 1000;
    params.nFramesTx = 4000;
else
    params.samplesPerFrame = 100000;
    params.nFramesTx = 400;
end
params.samplingFreq = rParams.MasterClockRate/rParams.InterpolationDecimationFactor;
params.fse = params.samplesPerFrame/params.symbolsPerFrame;
params.sampleDuration = 1/params.samplingFreq;
params.frameDuration = params.samplesPerFrame * params.sampleDuration;
params.symbolRate = params.symbolsPerFrame/params.frameDuration;
params.nBitsTx = params.symbolsPerFrame*params.M;
params.g = rcosdesign(params.roll_off, params.span, params.sps, 'sqrt');
end