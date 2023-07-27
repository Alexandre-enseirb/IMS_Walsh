function [] = generateRandomImage(mmap, h, w)
%GENERATERANDOMIMAGE genere une image random et la stocke dans l'espace de memoire partagee mmap
%
%   [] = generateRandomImage(mmap, h, w)


totalPixels = h*w;

newImage = uint8(randi([0, 255], totalPixels, 1));

mmap.Data = newImage(:);
