function [radio, txTime, nUnderrun] = sendPreamble()

radioParams = getRadioParams('tx');
commParams  = getCommParams('tx');



radio = comm.SDRuTransmitter("Platform", "B210", ...
    "SerialNum", "32752A2", ...
    "CenterFrequency", radioParams.centerFrequency, ...
    "ChannelMapping", [1, 2], ...
    "ClockSource", radioParams.ClockSource, ...
    "EnableBurstMode", radioParams.enableBurstMode, ...
    "Gain", radioParams.Gain, ... 
    "LocalOscillatorOffset", radioParams.LOOffset, ...
    "MasterClockRate",  radioParams.MasterClockRate, ...
    "NumFramesInBurst", radioParams.nFramesInBurstMode, ...
    "PPSSource", radioParams.PPSSource, ...
    "TransportDataType", radioParams.dataType, ...
    "InterpolationFactor",radioParams.InterpolationDecimationFactor);

%radio([complex(0) complex(0)]); % use it one time to init
dupColumn = length(radio.ChannelMapping)>1;
txTime = 0;
nUnderrun = 0;

fprintf("[TX] Starting emission...\n");

% Generation du message binaire
% Note: Dans cette version, on genere une seule trame, que l'on
% duplique autant de fois que demande
rng(12); % fixe la sequence binaire generee

preamble = repmat([0 1;1 0], 5, 1);
cPreamble = 1-2*preamble;
cPreamble = cPreamble(:,1) + 1j * cPreamble(:,2);
preambleUpsampled = upsample(cPreamble, commParams.fse);


symb = preambleUpsampled;

sl = conv(symb(:,1), commParams.g);
sl = sl(1:length(symb));

% Traitement du signal avant l'envoi
tx_signal = sl;
tx_signal_norm = tx_signal./max(abs(tx_signal));

% Duplication si deux voies de sortie
if dupColumn
    tx_sig = [tx_signal_norm.' tx_signal_norm.'];
else
    tx_sig = tx_signal_norm.';
end

!touch /tmp/toto
fprintf("[TX] Sending\n");
% Send the preamble
while isfile("/tmp/toto")
    underrun = radio(tx_sig);
    if underrun
        nUnderrun = nUnderrun + 1;
    end
end


fprintf("[TX] Job done\n");
end