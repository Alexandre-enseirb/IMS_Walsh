clear; clc; close all; dbstop if error;

setPath();

%% SETUP

load bitSynchro.mat; % Preamble

flag    = fullfile(tempdir, "radioRxflag");


disp("Setting up");

commParams = getCommParams('tx');
radioParams = getRadioParams('tx');
walshParams = getWalshParams();
scrambler = comm.Scrambler( ...
    "CalculationBase", commParams.scramblerBase, ...
    "Polynomial", commParams.scramblerPolynomial, ...
    "InitialConditions", commParams.scramblerInitState, ...
    "ResetInputPort", commParams.scramblerResetPort);

mflag    = memmapfile(flag, "Format", "int8" , "Writable", true);

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
M = 4;
phaseoffset = pi/4;

disp("Setup done");
% Set radio up

disp("Generating signal");
% Generation du message binaire
msg = img2symbols(commParams, scrambler, "Data/walsh.png");

% Ajout du preambule
preambleSymb = pskmod(bitSynchro, M, phaseoffset, InputType="bit");

% Concatenation
symbs = [preambleSymb.'; msg];

% Surech. + filtre de mise en forme
symbsUpsampled = upsample(symbs, commParams.fse);
symbsFiltered = conv(symbsUpsampled, commParams.g);

walshSig = wse(symbsFiltered, walshParams, length(symbsFiltered));

% Traitement du signal avant l'envoi
tx_signal = zeros(commParams.nFramesTx * commParams.samplesPerFrame, 1);
tx_signal(1:length(walshSig)) = walshSig;
tx_signal_norm = tx_signal./max(max(real(tx_signal)), max(imag(tx_signal)));

disp("Signal ready.");

% Duplication si deux voies de sortie
if dupColumn
    tx_sig = [tx_signal_norm tx_signal_norm];
else
    tx_sig = tx_signal_norm;
end

radio(tx_sig(1:commParams.samplesPerFrame, :));

if strcmpi(radioParams.ClockSource, "external")
    lockedStatus = referenceLockedStatus(radio);
    if lockedStatus
        disp("locked on ref");
    else
        disp("ERR! No lock possible. Aborting.");
        exit;
    end
    
end
disp("Emitting...");
mflag.Data(1) = uint8(1);
symbIdx = 1;
for i=1:commParams.nFramesTx
%i=1;
%while true
    startIdx = (i-1) * commParams.samplesPerFrame + 1;
    endIdx = i * commParams.samplesPerFrame;
    underrun = radio(tx_sig(startIdx:endIdx, :));
    if underrun
        disp(symbIdx);
        % nUnderrun = nUnderrun + 1;
    end

    %if i==commParams.nFramesTx+1
    %    i = 1;
    %end
    
end

mflag.Data(1) = uint8(0);

disp("Task failed succesfuly");