clear; clc; close all; dbstop if error;

setPath();

% Notes :
%
% Gain : 35
%
% CP Reel : -37 dBm
% CP Complexe : -33 dBm
%
% Jouable pour la radio Rx


%% PARAMETRES

load("bitSynchro.mat", "bitSynchro"); % Preamble

disp("Generation des parametres")
commParams = getCommParamsForWalshOverUDP("tx");
radioParams = getRadioParams("tx");
walshParams = getWalshParams();
colors = plotColors();

% Recuperation des parametres reseaux
MyIP = commParams.UDP.TxInetAddr;
targetIP = commParams.UDP.RxInetAddr;
port = commParams.UDP.Port;

% Ouverture du socket UDP
udpPort = udpport("IPV4", "LocalHost", MyIP, "LocalPort", port);

if ~handshake(udpPort, "tx", targetIP, port)
    error("Rx unavailable.");
end

udpPort.Timeout = 120;

TX_MSG_WAIT = uint8(0); % Indique a la radio tx d'attendre
TX_MSG_SEND = uint8(1); % Indique a la radio tx qu'elle peut emettre
TX_MSG_NOSIG = uint8(2); % Indique a la radio tx que le signal emis n'est pas exploitable

RX_MSG_WAIT = uint8(0); % Indique a la radio rx qu'aucun signal n'est envoye
RX_MSG_SEND = uint8(1); % Indique a la radio rx qu'un signal est en cours d'emission

imageHeight = 128;
imageWidth = 128;



disp("Instantiation radio")
radio = comm.SDRuTransmitter("Platform", "B210", ...
    "SerialNum", "327537B", ...
    "CenterFrequency", radioParams.centerFrequency, ...
    "ChannelMapping", radioParams.ChannelMapping, ...
    "ClockSource", radioParams.ClockSource, ...
    "EnableBurstMode", radioParams.enableBurstMode, ...
    "Gain", radioParams.Gain, ...
    "LocalOscillatorOffset", radioParams.LOOffset, ...
    "MasterClockRate",  radioParams.MasterClockRate, ...
    "PPSSource", radioParams.PPSSource, ...
    "TransportDataType", radioParams.dataType, ...
    "InterpolationFactor",radioParams.InterpolationDecimationFactor);

dupColumn = length(radio.ChannelMapping)>1;
txTime = 0;
nUnderrun = 0;


disp("Generation signal");
%tx_sig = generateSignal(commParams, walshParams, udpPort, dupColumn);
tx_sig = 1/4 * ones(commParams.samplesPerFrame, 1) + 1/4 * 1j * ones(commParams.samplesPerFrame, 1);
radio(tx_sig);

if strcmpi(radioParams.ClockSource, "external")
    lockedStatus = referenceLockedStatus(radio);
    if lockedStatus==1
        disp("Verrouillage reussi.");
    end
end
disp("Envoi");

symbIdx = 1;
sentImages = 0;
maxImagesSent = 10;
while sentImages < maxImagesSent
      
    % Generation du nouveau signal avec l'image en memoire
    disp("Generation du signal");
    tx_sig = generateSignal(commParams, walshParams, udpPort, dupColumn);
    
    
    % Indication au recepteur qu'on commence a emettre
    write(udpPort, 1, "uint8", targetIP, port);
    % Boucle d'emission
    disp("Emission");
    for i=1:commParams.nRadioFramesTxOSDM

        startIdx = (i-1) * commParams.samplesPerFrame + 1;
        endIdx = i * commParams.samplesPerFrame;

        underrun = radio(tx_sig(startIdx:endIdx, :));

        if underrun
            disp(symbIdx);
        end

    end
    sentImages = sentImages + 1;
    disp("Emission done");
end



function tx_sig = generateSignal(commParams, walshParams, udpPort, dupColumn)

disp("Awaiting signal");
waitForSignal(udpPort, 16384);
disp("Signal ready");
% Lecture de l'image dans le socket
imgData = read(udpPort, 16384, "uint8");

% Conversion en signal OSDM
sig = array2osdm(commParams, walshParams, imgData);

% Traitement du signal avant l'envoi (normalisation)
tx_signal_norm = sig./max(max(real(sig)), max(imag(sig)));

% Padding si necessaire
totalDataDuration = commParams.nRadioFramesTxOSDM * commParams.samplesPerFrame;
tx_signal_norm = [tx_signal_norm; zeros(totalDataDuration-length(tx_signal_norm), 1)];

% Duplication si deux voies de sortie
if dupColumn
    tx_sig = [tx_signal_norm tx_signal_norm];
else
    tx_sig = tx_signal_norm;
end

end

function waitForSignal(port, minData)

if exist("minData", "var")
    while port.NumBytesAvailable < minData
        pause(.1);
    end
else

    while port.NumBytesAvailable == 0
        pause(.1);
    end
end
end