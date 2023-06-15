function [status] = asynchronousRx(mflag)

radioParams = getRadioParams('rx');
commParams  = getCommParams('tx');

status = 0;

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

data_ = radio(); % call it once to initialize


i = 1;
datalength = length(data_);
nSamplesBuffered = 8*commParams.nFramesTx*datalength;
nFramesBuffered = nSamplesBuffered/datalength;
buffer1 = zeros(1, nSamplesBuffered);
buffer2 = zeros(1, nSamplesBuffered);
timeout = -1;

halfFramesBuffered = nFramesBuffered/2;

[name01, name02] = getNextNames();
while true

    [data_, ~, overrun] = radio();
    % buffer((i-1)*datalength+1 : i*datalength) = radio();
    % data_ = radio();
    % Ecriture en memoire
    if i <= halfFramesBuffered
        ii = i+halfFramesBuffered;
        buffer2((ii-1)*datalength+1:ii*datalength) = data_;
        buffer1((i-1)*datalength+1:i*datalength) = data_;
    elseif i <= nFramesBuffered
        ii = i-halfFramesBuffered;
        buffer1((i-1)*datalength+1:i*datalength) = data_;
        buffer2((ii-1)*datalength+1:ii*datalength) = data_;
    end

    % Debut d'envoi ?
    if mflag.Data(1) == uint8(1)
        timeout = nFramesBuffered;
        mflag.Data(1) = uint8(0);
    end

    timeout = timeout -1;
    i = i + 1;

    if i==nFramesBuffered+1
        i = 1;
    end

    % Sauvegarde une fois le timeout fini
    if timeout == 0
        save(name01, "buffer1");
        save(name02, "buffer2");
        [name01, name02] = getNextNames();
    end

end

end


function [name01, name02] = getNextNames()
counter = 0;
fileformat = "Rx_data_%d.mat";
while isfile(sprintf(fileformat, counter))
    counter = counter +1;
end
name01 = sprintf(fileformat, counter);
name02 = sprintf(fileformat, counter+1);
end