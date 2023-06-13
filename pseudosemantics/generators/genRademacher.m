function [r] = genRademacher(k,n)
%GENRADEMACHER genere des fonctions de Rademacher
%
%   GENRADEMACHER(k,n) genere la keme fonction de Rademacher sur n points

if 2^k > n
    error("Arguments invalides");
end

if log2(n) ~= floor(log2(n))
    error("Longueur invalide");
end

demi_T = n/2^(k+1);
vals = ones(1,demi_T);
r = ones(1,n);

for j=2:2^(k+1)
    start = (j-1)*demi_T + 1;
    stop  = j*demi_T;

    r(start:stop) = (-1)^(j-1) * vals;
end
end

