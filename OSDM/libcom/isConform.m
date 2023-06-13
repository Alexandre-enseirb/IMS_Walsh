function [conform] = isConform(sigFFT, mask)
%ISCONFORM verifie si le signal est conforme a un masque
%
%   conform = ISCONFORM(sigFFT, mask) verifie point par point si la puissance du signal depasse le
%   masque impose et retourne `true` ou `false` selon l'etat de conformite

conform = all(sigFFT <= mask);

end