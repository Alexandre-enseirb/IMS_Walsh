function [] = extract2x2()
%EXTRACT2X2 recupere l'image de Walsh et en fait un fichier ".mat" contenant
%toutes les combinaisons de 2x2 pixels pour un mapping OSDM
%
%   [] = extract2x2()

ImgFilename = "Data/walsh.png";

Img = imread(ImgFilename);
Img = squeeze(Img(:,:,1));

Img2x2 = zeros(2, 2, numel(Img)/4);

[h,w] = size(Img);

for j=1:2:h
    for i=1:2:w
        Img2x2(:,:,j*w+i) = Img(j:j+1, i:i+1);
    end
end

save("walsh_2x2_png.mat", "Img2x2");