function [sig] = img2walsh(commParams, walshParams, scrambler, imgfile)

    if ~exist("imgfile", "var")
        imgfile = "Data/walsh.png";
    end

    img = imread(imgfile);
    img = img(:,:,1);

    img_v = img(:);
    img_b = int2bit(img_v, commParams.bpiuint8, commParams.leftMSB);

    img_b_scrambled = scrambler(img_b, commParams.scramblerResetFlag);

    img_b = reshape(img_b_scrambled, commParams.bpiqpsk, []);

    symbs = pskmod(img_b, commParams.ModOrderQPSK, commParams.PhaseOffsetQPSK, InputType="bit");

    symbsUpsampled = upsample(symbs, commParams.fse);

    symbsConv = conv(symbsUpsampled, commParams.g);

    %sig = wse(symbsConv, walshParams, length(symbsConv));

    realSig = wse(real(symbsConv), walshParams, length(symbsConv));
    imagSig = wse(imag(symbsConv), walshParams, length(symbsConv));

    sig = realSig + 1j * imagSig;

end