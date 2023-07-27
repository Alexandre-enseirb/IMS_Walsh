function [img] = symbols2img(symbs, descrambler, phaseError, params)
%SYMBOLS2IMG convertit une suite de 65536 symboles QPSK en image grayscale 128x128

% Demodulation du signal
vals = pskdemod(symbs, params.ModOrderQPSK, params.PhaseOffsetQPSK + phaseError, "gray");

% Conversion en binaire, bit de poids fort a gauche
hatB = int2bit(vals, params.bpiqpsk, params.leftMSB);

% Decrambling (remise en place des bits)
hatBDescrambled = descrambler(hatB(:), true);

% Vectorisation et conversion en matrice
Bt = hatBDescrambled.';
Bt = Bt(:).';
hatMatBitImg = reshape(Bt(:), [], params.bpiuint8);

% Conversion en entiers en base 10
matImg = bit2int(hatMatBitImg, params.bpiuint8, params.leftMSB);
img = reshape(matImg,128,128);

end