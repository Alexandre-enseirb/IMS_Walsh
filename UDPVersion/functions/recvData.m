function [radio, data, nOverrun] = recvData()

radioParams = getRadioParams('rx');
commParams  = getCommParams('rx');


radio = comm.SDRuReceiver("Platform", "B210", ...
    "SerialNum", "327537B", ...
    "CenterFrequency", radioParams.centerFrequency, ...
    "ChannelMapping", 1, ...
    "ClockSource", radioParams.ClockSource, ...
    "EnableBurstMode", radioParams.enableBurstMode, ...
    "Gain", radioParams.Gain, ... 
    "LocalOscillatorOffset", radioParams.LOOffset, ...
    "MasterClockRate",  radioParams.MasterClockRate, ...
    "NumFramesInBurst", radioParams.nFramesInBurstMode, ...
    "PPSSource", radioParams.PPSSource, ...
    "TransportDataType", radioParams.dataType, ...
    "DecimationFactor",radioParams.InterpolationDecimationFactor);
% dupColumn = length(radio.ChannelMapping)>1;

data = zeros(1, 10000000);
fprintf("[RX] Starting reception...\n");
nOverrun = 0;

!rm -f VRX
% Wait for TX
delay = 0.01;
while isfile("VTX")
    pause(delay);
end

ptr = 1;
while true
    
    [data_, ~, overrun] = radio();
    if ~overrun
    
        data(ptr:ptr+length(data_)-1) = data_;
        
    else
        nOverrun = nOverrun + 1;
    end
    ptr = ptr + length(data_);
    if ptr + length(data_) > length(data)
        break;
    end
end

disp(nOverrun);
data = data(:);
fprintf("[RX] Job done\n");
end