function [radio, txTime, nUnderrun] = sendModulatedData()

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

dupColumn = length(radio.ChannelMapping)>1;
txTime = 0;
nUnderrun = 0;

fprintf("[TX] Starting emission...\n");

% Generation du message binaire
% Note: Dans cette version, on genere une seule trame, que l'on
% duplique autant de fois que demande
rng(12); % fixe la sequence binaire generee
bits = randi([0,1], commParams.symbolsPerFrame, commParams.M);

% Modulation QPSK
c = 1-2*bits;
c = c(:,1) + 1j*c(:,2);

% Upsampling des symboles et convolution par le filtre de mise en forme
symb = upsample(c, commParams.fse);
symb = repmat(symb, commParams.nFramesTx, 1);

preamble = repmat([0 1;1 0], 5, 1);
cPreamble = 1-2*preamble;
cPreamble = cPreamble(:,1) + 1j * cPreamble(:,2);
preambleUpsampled = upsample(cPreamble, commParams.fse);


symb(1:length(preambleUpsampled), 1) = preambleUpsampled;

sl = conv(symb(:,1), commParams.g);
sl = sl(1:length(symb));

% Traitement du signal avant l'envoi
tx_signal = sl;
tx_signal_norm = tx_signal./max(abs(tx_signal));

% Duplication si deux voies de sortie
if dupColumn
    tx_sig = [tx_signal_norm tx_signal_norm];
else
    tx_sig = tx_signal_norm;
end

!rm -f VTX

for i=1:commParams.nFramesTx
    startIdx = (i-1) * commParams.samplesPerFrame + 1;
    endIdx = i * commParams.samplesPerFrame;
    underrun = radio(tx_sig(startIdx:endIdx, :));
    if underrun
        nUnderrun = nUnderrun + 1;
    end
end


fprintf("[TX] Job done\n");
end