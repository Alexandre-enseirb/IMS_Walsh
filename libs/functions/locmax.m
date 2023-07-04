function [vals, idx] = locmax(sig, threshold)
%LOCMAX trouve les maximum locaux d'une fonction sur tout son intervalle de
%definition
%
%   [vals, idx] = locmax(sig) retourne les positions et les valeurs de tous
%   les maximum locaux du signal, sauf s'ils valent 0
%
%   [vals, idx] = locmax(sig, threshold) retourne les positions et les
%   valeurs de tous les maximum locaux du signal tant qu'ils valent plus de
%   'threshold' en valeur absolue


if ~exist("threshold", "var")
    threshold=0;
end

kernel = [-1 1]; % noyau de differentiation

dsig = conv(sig, kernel, 'same'); % differentielle du signal

chgt_sign = sign(dsig(1:end-1)) == sign(dsig(2:end)); % 0 si changement de signe

[~, idx] = find(chgt_sign == 0);
vals = sig(idx);
i = abs(vals) > threshold;

vals = vals(i);
idx  = idx (i);

% alternance max/min
if vals(1) > vals(2)
    vals = vals(1:2:end);
    idx = idx(1:2:end);
else
    vals = vals(2:2:end);
    idx = idx(2:2:end);
end


end

