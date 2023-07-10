function [sig] = img2walsh(commParams, walshParams, scrambler, imgfile)

if ~exist("imgfile", "var")
    imgfile = "Data/walsh.png";
end

% Lecture du fichier
img = imread(imgfile);
img = img(:,:,1); % Extraction du canal Rouge (transmission en grayscale)

% Conversion en vecteur
img_v = img(:);
% Conversion binaire, bit de poids fort a gauche
img_b = int2bit(img_v, commParams.bpiuint8, commParams.leftMSB);

% Scrambling (pour avoir une repartition presque uniforme des bits et eviter des
% comportements etranges au niveau des radios)
img_b_scrambled = scrambler(img_b, commParams.scramblerResetFlag);

% Assemblage des bits 2 a 2 pour la modulation
img_b = reshape(img_b_scrambled, commParams.bpiqpsk, []);

% Modulation
symbs = pskmod(img_b, commParams.ModOrderQPSK, commParams.PhaseOffsetQPSK, InputType="bit");

% Surechantillonnage
symbsUpsampled = upsample(symbs, commParams.fse);

% Convolution par le filtre de mise en forme
symbsConv = conv(symbsUpsampled, commParams.g);

% Developpement en serie de Walsh du signal
realSig = wse(real(symbsConv), walshParams, length(symbsConv));
imagSig = wse(imag(symbsConv), walshParams, length(symbsConv));

sig = realSig + 1j * imagSig;

end