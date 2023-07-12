function coefout = quantification(coefin, n, max_bin)
%% Quantization
% Arrondit les valeurs de coefin selon un pas de 1/max_bin, a l'entier
% inferieur (positif) ou superieur (negatif)
%
% /!\ Ne garantit pas de pouvoir tout coder sur n bits
if ~exist("max_bin", "var")
    max_bin = bi2de(ones(1,n-1));
end

coefout = coefin;
end


% [l,c] = size(coefin);
% 
% max_bin_positif = max_bin;
% max_bin_negatif = max_bin+1;
% 
% coefout(coefin<=0) = ceil(max_bin_negatif*coefin(coefin<=0))/max_bin_negatif;
% coefout(coefin>0)  = floor(max_bin_positif*coefin(coefin>0))/max_bin_positif;
% 
% coefout = reshape(coefout, l,c);
% end