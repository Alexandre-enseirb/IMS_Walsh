function [newImage] = generateRandomImageUDP(udpPort, h, w, destinationIP, port)
%GENERATERANDOMIMAGEUDP genere une image random et l'envoie dans le socket udp selectionne
%
%   [newImage] = generateRandomImage(mmap, h, w)


totalPixels = h*w;

newImage = uint8(randi([0, 255], totalPixels, 1));

write(udpPort, newImage, "uint8", destinationIP, port);
