function [status] = imgRxOSDMOverUDP(udpPort, targetIP, port)

disp("Setting up.");
radioParams = getRadioParams('rx');
commParams  = getCommParamsForWalsh('rx');
walshParams = getWalshParams();

set(udpPort, "Timeout", 60);
status = 0;

filename = "OSDM_over_UDP_with_response.mat";

radio = comm.SDRuReceiver("Platform", "B210", ...
    "SerialNum", "3218C8E", ...
    "CenterFrequency", radioParams.centerFrequency, ...
    "ChannelMapping", 1, ...
    "ClockSource", radioParams.ClockSource, ...
    "EnableBurstMode", radioParams.enableBurstMode, ...
    "Gain", radioParams.Gain, ...
    "LocalOscillatorOffset", radioParams.LOOffset, ...
    "MasterClockRate",  radioParams.MasterClockRate, ...
    "PPSSource", radioParams.PPSSource, ...
    "TransportDataType", radioParams.dataType, ...
    "DecimationFactor",radioParams.InterpolationDecimationFactor, ...
    "OutputDataType", "double", ...
    "TransportDataType", "int16", ...
    "SamplesPerFrame", commParams.samplesPerFrame);
% dupColumn = length(radio.ChannelMapping)>1;


% filename = sprintf(filename, walshParams.osr);
%filename = "img_rx_clock_pps_rrc.mat";

data = zeros(1, 10000000);
fprintf("[RX] Starting reception...\n");
nOverrun = 0;
disp("Setup done.");
data_ = radio(); % call it once to initialize

if strcmpi(radioParams.ClockSource, "external")
    lockedStatus = referenceLockedStatus(radio);
    if lockedStatus
        disp("locked on ref");
    else
        disp("ERR! No ref available. aborting.");
        exit;
    end
end

i = 1;
datalength = length(data_);
nBuffers = 2;
nBufferWindows = 2*radioParams.RxOversampling*commParams.nRadioFramesTxOSDM;
buffer1 = zeros(datalength, nBufferWindows);
buffer2 = zeros(datalength, nBufferWindows);
timeout = -1;

halfBufferWindows = nBufferWindows/2;
disp("Start listening.");
timeout = nBufferWindows;
% fprintf("Now awaiting Tx (timeout: %d)\n", udpPort.Timeout);

% data = read(udpPort, 1, "uint8");

% fprintf("Gotcha homie\n");
timeout = nBufferWindows;
decrement = 0;
% write(udpPort, 1, "uint8", targetIP, port);
ongoing = true;
while ongoing

    [buffer1(:, i), ~, overrun] = radio();
    % buffer((i-1)*datalength+1 : i*datalength) = radio();
    % data_ = radio();
    % Ecriture en memoire
    if i <= halfBufferWindows
        ii = i+halfBufferWindows;
    elseif i <= nBufferWindows
        ii = i-halfBufferWindows;
    end
    buffer2(:, ii) = buffer1(:, i);

    % Reception de donnees, on commence a decrementer
    if udpPort.NumBytesAvailable ~= 0
        decrement = 1;
        udpPort.flush();
    end

    timeout = timeout - decrement;
    i = i + 1;

    if i==nBufferWindows+1
        i = 1;
    end

    % Sauvegarde une fois le timeout fini
    if timeout == 0
        disp("Saving... Please do not turn off the script.");
        save(filename, "buffer1", "buffer2", "commParams", "radioParams", "walshParams");
        disp("Saving done. Exiting.");
        ongoing = false;
        %exit;
    end

end

end

