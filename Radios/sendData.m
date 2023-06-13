function [radio, txTime, nUnderrun] = sendData()

radioParams = getRadioParams('tx');
commParams  = getCommParams();


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
tic;
for i=1:commParams.nFramesTx
    bits = randi([0,1], commParams.symbolsPerFrame, commParams.M);
    
    c = 1-2*bits;
    c = c(:,1) + 1j*c(:,2);
    
    symb = upsample(c, commParams.fse);
    
    sl = conv(symb(:,1), commParams.g);
    sl = sl(1:length(symb));
    
    tx_signal = sl;
    tx_signal_norm = tx_signal./max(abs(tx_signal));
    
    if dupColumn
        tx_sig = [tx_signal_norm tx_signal_norm];
    else
        tx_sig = tx_signal_norm;
    end

    underrun = radio(tx_sig);
    if underrun
        nUnderrun = nUnderrun + 1;
    end
end
txTime = txTime + toc;

fprintf("[TX] Job done\n");
end