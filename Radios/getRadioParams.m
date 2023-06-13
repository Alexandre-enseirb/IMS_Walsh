function [params] = getRadioParams(radioType)

params = struct();
params.centerFrequency = 500e6;
params.LOOffset = 0;
params.enableBurstMode = true;
params.nFramesInBurstMode = 100;
params.dataType = 'int16';
params.PPSSource = 'internal';
params.ClockSource = 'external';
params.MasterClockRate = 30e6;

if strcmp(radioType, 'tx') || strcmp(radioType, 'Tx')
    params.Gain = 40;
    params.ChannelMapping = [1 2];
    params.InterpolationDecimationFactor = 30;
elseif strcmp(radioType, 'rx') || strcmp(radioType, 'Rx')
    params.Gain = 35;
    params.ChannelMapping = 1;
    params.InterpolationDecimationFactor = 30;
end