%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Permet la transmission de l'OSDM en emettant
% une image 128x128 grayscale de J. Walsh
%
% Pour observer les donnees sur une plus longue periode,
% voir OSDMVisualizer.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

targetIP = "169.254.158.40";
myIP = "169.254.103.193";
port = 8080;

udpPort = udpport("IPV4", "LocalHost", myIP, "LocalPort", port);


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
[sig]=img2osdm(commParams, radioParams, walshParams, scrambler);
% sig = upsample(sig, commParams.fse);
% sig = conv(sig, commParams.g);
% disp("Generation signal complexe");
% sigC = sig + 1j * sig;
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

radio(tx_sig(1:commParams.samplesPerFrame, :));

if strcmpi(radioParams.ClockSource, "external")
    lockedStatus = referenceLockedStatus(radio);
    if lockedStatus==1
        disp("Verrouillage reussi.");
    end
end
disp("Envoi");
write(udpPort, 1, "uint8", targetIP, port);
% data = read(udpPort, 1, "uint8");
%mflag.Data(1) = uint8(1);
symbIdx = 1;
for i=1:commParams.nRadioFramesTxOSDM

    startIdx = (i-1) * commParams.samplesPerFrame + 1;
    endIdx = i * commParams.samplesPerFrame;
    
    underrun = radio(tx_sig(startIdx:endIdx, :));
    
    if underrun
        disp(symbIdx);
    end
end

write(udpPort, 0, "uint8", targetIP, port);
