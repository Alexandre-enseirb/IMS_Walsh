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

flag    = fullfile(tempdir, "radioRxflag");
sendFlagFile = fullfile(tempdir, "radioTxflag");
mflag    = memmapfile(flag, "Format", "int8" , "Writable", true);
sendFlag = memmapfile(sendFlagFile, "Format", "int8", "Writable", true);
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
disp("Generation signal complexe");
sigC = sig + 1j * sig;
%sigC = sig;
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

symbIdx = 1;
for iBER=1:commParams.nBERPoints
    disp("Waiting...");
    while sendFlag.Data(1) == 0
        pause(.1);
    end
    sendFlag.Data(1) = 0;
    disp("Let's go.");
    mflag.Data(1) = uint8(1);
    for i=1:commParams.nRadioFramesTxOSDM
    % i=1;
    % while true
        startIdx = (i-1) * commParams.samplesPerFrame + 1;
        endIdx = i * commParams.samplesPerFrame;
        
        underrun = radio(tx_sig(startIdx:endIdx, :));
        
        if underrun
            disp(symbIdx);
            % nUnderrun = nUnderrun + 1;
        end
    
    %    if i==commParams.nFramesTx+1
    %        i = 1;
    %    end
        
    end
    radio.Gain = radio.Gain - 1;
end
mflag.Data(1) = uint8(0);
