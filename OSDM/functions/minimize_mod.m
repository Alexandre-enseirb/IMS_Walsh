function [mu, mod_] = minimize_mod(alpha, beta)
%MINIMIZE_MOD minimise le module d'une combinaison lineaire de deux nombres
% complexes
%
%   [mu] = minimize_mod(alpha, beta) trouve la valeur de mu de sorte a
%   minimiser la quantite |a + m*b|^2 par une annulation de la derivee.

alpha_r = real(alpha);
alpha_i = imag(alpha);
beta_r  = real(beta);
beta_i  = imag(beta);

% c1 = alpha_r * beta_r;
% c2 = alpha_i * beta_i;
% c3 = beta_r^2 + beta_i^2;
% 
% c4 = c1 + c2;

mu = - (alpha_r*beta_r + alpha_i*beta_i)./(beta_r.^2+beta_i.^2);

mod_ = abs(alpha + mu.*beta);
end

