function [result, newKey] = isAKey(queryKey, keysArray)
%ISAKEY checks if the queried key is part of the keys of the dictionnary
%/!\ Only designed to work with a very specific structure of keys

%% Manipulations memoire pour faire les calculs sans boucle for
queryKeyVectorized = queryKey(:);
% isolation des coefficients
queryKeyCoeffs = queryKeyVectorized(1:2:end);
% Mise en forme de la matrice de cles
keysArrayMatrix = [keysArray{:}];
keysArrayCoeffs = keysArrayMatrix(1,:);
keysArrayValues = keysArrayMatrix(2,:);
% Entrelacement coefficient/valeur
interleavedKeysArray = zeros(2*length(keysArrayCoeffs), 1);
interleavedKeysArray(1:2:end) = keysArrayCoeffs;
interleavedKeysArray(2:2:end) = keysArrayValues;

interleavedKeysArray = reshape(interleavedKeysArray, 6, []);

% Difference entre chaque cle et la cle que l'on veut inserer
% Si la cle demandee fait partie du "trousseau", on aura une colonne
% avec que des 0
diff = interleavedKeysArray - repmat(queryKeyVectorized, 1, size(interleavedKeysArray, 2));

diffAll = sum(abs(diff), 1);
diffCoeffs = sum(abs(diff(1:2:end, :)), 1);
if any(diffAll==0) % la cle existe
    result = true;
    newKey = queryKey;
elseif any(diffCoeffs==0)
    % A-t-on d'autres combinaisons avec les memes coeffs ?
    result = true;
    newKey = keysArray{find(diffCoeffs, 1)};
else
    result=false;
    newKey = {};
end



end