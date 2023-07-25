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


%% Parameters


load bitSynchro.mat; % Preamble

TX_MSG_WAIT = uint8(0); % Indique a la radio tx d'attendre
TX_MSG_SEND = uint8(1); % Indique a la radio tx qu'elle peut emettre
TX_MSG_NOSIG = uint8(2); % Indique a la radio tx que le signal emis n'est pas exploitable

RX_MSG_WAIT = uint8(0); % Indique a la radio rx qu'aucun signal n'est envoye
RX_MSG_SEND = uint8(1); % Indique a la radio rx qu'un signal est en cours d'emission

% Fichiers pour la communication de donnees
flag    = fullfile(tempdir, "radioRxflag");
sendFlagFile = fullfile(tempdir, "radioTxflag");
imageFilename = fullfile(tempdir, "sharedImage128x128");

if ~isfile(imageFilename)
    f = fopen(imageFilename, "w+");
    fwrite(f, zeros(16384, 1, "uint8"));
    fclose(f);
end

disp("Initialisation des fichiers.");
% Mapping en memoire des fichiers
mflag    = memmapfile(flag, "Format", "int8" , "Writable", true);
sendFlag = memmapfile(sendFlagFile, "Format", "int8", "Writable", true);
imageFile = memmapfile(imageFilename, "Format", "uint8", "Writable", true);

imageHeight = 128;
imageWidth = 128;

disp("Generation des parametres")
commParams = getCommParamsForWalsh("tx");
radioParams = getRadioParams("tx");
walshParams = getWalshParams();
colors = plotColors();

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

scrambler = comm.Scrambler( ...
    "CalculationBase", commParams.scramblerBase, ...
    "Polynomial", commParams.scramblerPolynomial, ...
    "InitialConditions", commParams.scramblerInitState, ...
    "ResetInputPort", commParams.scramblerResetPort);

disp("Generation signal");
tx_sig = generateSignal(commParams, walshParams, imageFile, dupColumn);

radio(tx_sig(1:commParams.samplesPerFrame, :));

if strcmpi(radioParams.ClockSource, "external")
    lockedStatus = referenceLockedStatus(radio);
    if lockedStatus==1
        disp("Verrouillage reussi.");
    end
end
disp("Envoi");

symbIdx = 1;
while radio.Gain >= 8
    disp("Waiting...");
    % Attente de la radio receptrice
    while sendFlag.Data(1) == TX_MSG_WAIT
        pause(.1);
    end
    % Petit delai supplementaire pour garantir qu'elle demarre avant l'emetteur
    pause(1);

    % Ajustement du gain si necessaire
    % if sendFlag.Data(1) == TX_MSG_NOSIG
    %     radio.Gain = radio.Gain + 1;
    % end
    
    % On remet le flag sur "attente" pour le prochain tour de boucle
    sendFlag.Data(1) = TX_MSG_WAIT;
    % Generation du nouveau signal avec l'image en memoire
    disp("Generation du signal");
    generateRandomImage(imageFile, imageHeight, imageWidth);
    tx_sig = generateSignal(commParams, walshParams, imageFile, dupColumn);
    
    % Indication au recepteur qu'on commence a emettre
    mflag.Data(1) = RX_MSG_SEND;
    % Boucle d'emission
    for i=1:commParams.nRadioFramesTxOSDM

        startIdx = (i-1) * commParams.samplesPerFrame + 1;
        endIdx = i * commParams.samplesPerFrame;

        underrun = radio(tx_sig(startIdx:endIdx, :));

        if underrun
            disp(symbIdx);
        end

    end
    % radio.Gain = radio.Gain - 1;
end
mflag.Data(1) = RX_MSG_WAIT;


function tx_sig = generateSignal(commParams, walshParams, imageFile, dupColumn)

sig = mmap2osdm(commParams, walshParams, imageFile);

sigC = sig;
% Traitement du signal avant l'envoi
tx_signal_norm = sigC./max(max(real(sigC)), max(imag(sigC)));

totalDataDuration = commParams.nRadioFramesTxOSDM * commParams.samplesPerFrame;

tx_signal_norm = [tx_signal_norm; zeros(totalDataDuration-length(tx_signal_norm), 1)];

% Duplication si deux voies de sortie
if dupColumn
    tx_sig = [tx_signal_norm tx_signal_norm];
else
    tx_sig = tx_signal_norm;
end

end