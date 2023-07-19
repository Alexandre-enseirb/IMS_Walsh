function [status] = imgRxOSDM(mflag)

disp("Setting up.");
radioParams = getRadioParams('rx');
commParams  = getCommParamsForWalsh('rx');
walshParams = getWalshParams();

status = 0;

filenames = ["OSDM_img_rx_no_clock_no_pps_rrc_Complex_preamble_QPSK.mat", ...
             "OSDM_img_rx_clock_no_pps_rrc_Complex_preamble_QPSK.mat", ...
             "OSDM_img_rx_clock_pps_rrc_Complex_preamble_QPSK.mat"];

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



if strcmpi(radioParams.ClockSource, 'external')
    if strcmpi(radioParams.PPSSource, 'external')
        filename = filenames(3); % Clock && PPS
    else
        filename = filenames(2); % Clock only
    end
else
    filename = filenames(1); % Nothing
end

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
while true

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

    % Debut d'envoi ?
    if mflag.Data(1) == uint8(1)
        % disp("Data detected.");
        timeout = nBufferWindows;
        mflag.Data(1) = uint8(0);
    end

    timeout = timeout -1;
    i = i + 1;

    if i==nBufferWindows+1
        i = 1;
    end

    % Sauvegarde une fois le timeout fini
    if timeout == 0
        disp("Saving... Please do not turn off the script.");
        save(filename, "buffer1", "buffer2", "commParams", "radioParams", "walshParams");
        disp("Saving done. Exiting.");
        exit;
    end

end

end

