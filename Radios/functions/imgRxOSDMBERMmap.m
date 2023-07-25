function [BER] = imgRxOSDMBERMmap(mflag, sendFlag, mmap)

format short g

TX_MSG_WAIT = uint8(0); % Indique a la radio tx d'attendre
TX_MSG_SEND = uint8(1); % Indique a la radio tx qu'elle peut emettre
TX_MSG_NOSIG = uint8(2); % Indique a la radio tx que le signal emis n'est pas exploitable

RX_MSG_WAIT = uint8(0); % Indique a la radio rx qu'aucun signal n'est envoye
RX_MSG_SEND = uint8(1); % Indique a la radio rx qu'un signal est en cours d'emission

disp("Paramétrage.");
radioParams = getRadioParams('rx');
commParams  = getCommParamsForWalsh('rx');

disp("Instantiation de la radio.");
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
nBufferWindows = 2*radioParams.RxOversampling*commParams.nRadioFramesTxOSDM;
buffer1 = zeros(datalength, nBufferWindows);
buffer2 = zeros(datalength, nBufferWindows);
timeout = -1;
BER = zeros(1, commParams.nBERPoints);
currentBER = 1;

sendFlag.Data(1) = TX_MSG_SEND;
halfBufferWindows = nBufferWindows/2;
errorsCount = 0;
bitsCount = 0;
invalids = 0;
disp("Start listening.");

while errorsCount < commParams.nErrorsMinimum && bitsCount < commParams.nBitsMinimum

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
    if mflag.Data(1) == RX_MSG_SEND
        %disp("Data detected.");
        timeout = nBufferWindows;
        mflag.Data(1) = RX_MSG_WAIT;
    end

    timeout = timeout -1;
    i = i + 1;

    if i==nBufferWindows+1
        i = 1;
    end

    % Sauvegarde une fois le timeout fini
    if timeout == 0
        fprintf("Studying %d\n", 35-currentBER+1);
        [BER(currentBER), errFlag, err_cnt, bit_cnt, invalidCoeffs] = OSDMComputeBERFromMmap(buffer1, buffer2, commParams, mmap);
        if errFlag
            
            errorsCount = errorsCount + err_cnt;
            bitsCount = bitsCount + bit_cnt;
            invalids = invalids + invalidCoeffs;
            fprintf("Got BER: %d\n", BER(currentBER));
            
            currentBER = currentBER+1; 
            % radio.Gain = radio.Gain + 1;
        end
        sendFlag.Data(1) = TX_MSG_SEND;
    end
end
txParams = getRadioParams('tx');
save(sprintf("BER_analysis_Tx_%d_Rx_%d.mat", txParams.Gain, radioParams.Gain), ...
    "BER", "errorsCount", "bitsCount");
end

