function [sig_Walsh, Xw_b] = wse(sig_in, params, N, truncature)
%WSE est la decomposition en series de Walsh d'un signal
%
%   [SIG_WALSH] = WSE(SIG_IN, PARAMS, N) calcule les coefficients de Walsh
%   associes a un signal SIG_IN et retourne sa decomposition en series de
%   Walsh. Les parametres PARAMS.OSR et PARAMS.ORDER sont utilises pour
%   calculer le surechantillonnage du signal et l'ordre de la decomposition
%   de Walsh. N est la duree du signal produit et correspond au plus petit
%   commun multiple de la duree d'une periode de rafraichissement et de la
%   periode associee a la plus haute frequence du signal.
%
%   [SIG_WALSH, XW_B] = WSE(SIG_IN, PARAMS, N) calcule les coefficients de
%   Walsh associes a un signal SIG_IN et retourne sa decomposition en
%   series de Walsh. Les parametres PARAMS.OSR et PARAMS.ORDER sont
%   utilises pour calculer le surechantillonnage du signal et l'ordre de 
%   la decomposition de Walsh. XW_B contient les 2^PARAMS.ORDER
%   coefficients de Walsh utilises pour la reconstruction.

if ~exist("truncature", "var") || (isa(truncature,"logical") && truncature == false)
    truncature = false;
elseif ~isa(truncature,"double") || int64(truncature) ~= truncature
    error("Please specify an integer for the truncature");
end

Xw = dwt(sig_in(1:params.osr:end), params.W, params.order, true);
[~, nWindows] = size(Xw);

sig_Walsh = zeros(1, N);

Xw_b = quantification(Xw, params.nBitsAmp, params.maxBin);
% Xw_b = Xw;
[len,~] = size(Xw_b);
mid = len/2;
if ~isa(truncature,"logical")
    % tri des valeurs dans l'ordre decroissant, par V.A.
    [vals, idx] = sort(abs(Xw_b),'descend');
    % Ajout du signe
    vals = vals.*sign(Xw_b(idx));
    
    % Troncature par colonne
    for j=1:nWindows
        % Vecteur de coeffs non nuls sur la colonne
        Xw_b_nz = vals(vals(:,j)~=0,j);
        
        % Vecteur tronque
        Xw_b_nz = truncate_(Xw_b_nz, truncature);

        % Affectation
        vals(vals(:,j)~=0,j) = Xw_b_nz;
        Xw_b(idx(:,j),j) = vals(:,j);
    end
end
%figure();
for i=1:nWindows
    sig_Walsh((i-1)*params.nCoeffs+1:i*params.nCoeffs) = params.W*Xw_b(:,i);
    %plot(params.time_axis(1:i*params.nCoeff), sig_Walsh(1:i*params.nCoeff)); grid on;
end
sig_Walsh = repmat(sig_Walsh(1:nWindows*params.nCoeffs), params.osr, 1);
sig_Walsh = sig_Walsh(:);
end

