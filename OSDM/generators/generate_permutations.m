function [coeffsPerms] = generate_permutations(coeffs, params)
%GENERATE_PERMUTATIONS genere des combinaisons de fonctions de Walsh
%
%   GENERATE_PERMUTATIONS(coeffs, params) utilise les champs definis dans
%   params et les coefficients donnes par coeffs pour generer toutes les
%   combinaisons de params.depth coefficients codes sur params.nBitsAmp
%   bits d'amplitude.
%
%   La fonction part du principe que les coefficients sont tries par
%   importance. Le premier coefficient de coeffs est toujours pris en
%   compte, et les autres coefficients ne peuvent pas avoir une amplitude
%   supérieure dans les combinaisons generees

coeffsPerms = perms(coeffs(2:end));

end

