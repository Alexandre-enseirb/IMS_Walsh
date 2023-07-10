function [p] = intercorr(r,s)
%INTERCORR calcule une intercorrelation simplifiee entre deux signaux
%
% La formule d'intercorrelation utilisee est la suivante (compiler en LaTeX pour la lire)
% Avec $\mathbf{r} = \left[r_1, ..., r_N \right], \mathbf{s} = \left[s_1, ..., s_M\right], N \geq M$
%   E[n] = \sum_{m=0}^{M} r[m+n] \times \bar s[m]

T = length(s);

offset=1;
p=[];

% Tant qu'on ne cherche pas a acceder a des echantillons hors du signal
while offset+T < length(r) 
    E =  sum(r(offset:offset+T-1).*conj(s));
    
    p = [p E];
    
    
    offset = offset+1;
end

end

