function [tx_signal_norm] = generateNewUSRPFrameQPSK(symbolsPerFrame, oversamplingFactor, cols)

M = 2;

g = 1/oversamplingFactor * ones(oversamplingFactor, 1);

bits = randi([0,1], symbolsPerFrame, M);

c = 1-2*bits;
c = c(:,1) + 1j*c(:,2);

symb = upsample(c, oversamplingFactor);

sl = conv(symb(:,1), g);
sl = sl(1:length(symb));

tx_signal = sl;
tx_signal_norm = tx_signal./max(abs(tx_signal));

if cols>1
    tx_signal_norm = [tx_signal_norm tx_signal_norm];

end