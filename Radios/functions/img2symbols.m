function [symbs] = img2symbols(commParams, scrambler, imgfile)
%IMG2SYMBOLS convertit une image en symboles QPSK

if ~exist("imgfile", "var")
    imgfile = "Data/walsh.png";
end

img = imread(imgfile);
img = img(:,:,1);

img_v = img(:);
img_b = int2bit(img_v, commParams.bpiuint8, commParams.leftMSB);

img_b_scrambled = scrambler(img_b, commParams.scramblerResetFlag);

img_b = reshape(img_b_scrambled, commParams.bpiqpsk, []);

symbs = pskmod(img_b, commParams.ModOrderQPSK, commParams.PhaseOffsetQPSK, InputType="bit").';