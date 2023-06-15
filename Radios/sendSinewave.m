function [radio, txTime, nUnderrun] = sendSinewave()

radioParams = getRadioParams('tx');
commParams  = getCommParams('tx');


delay = 0.01;
radio = comm.SDRuTransmitter("Platform", "B210", ...
    "SerialNum", "327537B", ...
    "CenterFrequency", radioParams.centerFrequency, ...
    "ChannelMapping", [1, 2], ...
    "ClockSource", radioParams.ClockSource, ...
    "EnableBurstMode", radioParams.enableBurstMode, ...
    "Gain", radioParams.Gain, ... 
    "LocalOscillatorOffset", radioParams.LOOffset, ...
    "MasterClockRate",  radioParams.MasterClockRate, ...
    "NumFramesInBurst", radioParams.nFramesInBurstMode, ...
    "PPSSource", radioParams.PPSSource, ...
    "TransportDataType", radioParams.dataType, ...
    "InterpolationFactor",radioParams.InterpolationDecimationFactor);
dupColumn = length(radio.ChannelMapping)>1;
txTime = 0;
nUnderrun = 0;

fprintf("[TX] Starting emission...\n");

f0 = 100e3;
timeAxis = (1:commParams.samplesPerFrame)/commParams.samplingFreq;
tx_signal = exp(1j*2*pi*f0*timeAxis).';
tx_signal_norm = tx_signal./max(abs(tx_signal));

if dupColumn
    tx_sig = [tx_signal_norm tx_signal_norm];
else
    tx_sig = tx_signal_norm;
end

!rm -f VTX
tic;
while toc < 20
    
    underrun = radio(tx_sig);
    if underrun
        nUnderrun = nUnderrun + 1;
    end
end


fprintf("[TX] Job done\n");
end