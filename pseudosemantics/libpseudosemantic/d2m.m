function [mat] = d2m(dict, input)
%D2M convertit les entrees d'un dictionnaire en matrice
% Si les entrees du dictionnaire sont des scalaires, la fonction retourne un vecteur ligne avec toutes les valeurs
% Si les entrees sont des vecteurs et/ou des matrices, la fonction retourne une matrice dont les colonnes sont les
% differentes valeurs, converties en vecteur colonne. Il est obligatoire que toutes les entrees soient de la meme
% taille.

if ~exist("input", "var")
    input='values';
end

if strcmp(input, "values")
    keys = dict.keys;
    firstValueCell = dict(keys(1));
    firstValueSz = size(firstValueCell{1,1});
    mat = zeros(prod(firstValueSz, "all"), length(keys));
    for ikey = 1:length(keys)
        value = dict(keys(ikey));
        mat(:, ikey) = value{1,1}(:);
    end
elseif strcmp(input, "keys")
    keys = dict.keys;
    firstValueCell = keys(1);
    firstValueSz = size(firstValueCell{1,1});
    mat = zeros(prod(firstValueSz, "all"), length(keys));
    for ikey = 1:length(keys)
        value = keys(ikey);
        mat(:, ikey) = value{1,1}(:);
    end
else
    error("Unrecognized input");
end


end

