function [img] = symbols2img(symbs, descrambler, phaseError, params)
%SYMBOLS2IMG convertit une suite de 65536 symboles QPSK en image grayscale 128x128

vals = pskdemod(symbs, params.ModOrderQPSK, params.PhaseOffsetQPSK + phaseError, "gray");

hatB = int2bit(vals, params.bpiqpsk, params.leftMSB);

hatBDescrambled = descrambler(hatB(:));

Bt = hatBDescrambled.';
Bt = Bt(:).';

% affichage
hatMatBitImg = reshape(Bt(:), [], params.bpiuint8);
matImg = bit2int(hatMatBitImg, params.bpiuint8, params.leftMSB);
img = reshape(matImg,128,128);

end