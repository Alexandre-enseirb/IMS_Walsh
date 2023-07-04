function [sig_Walsh, Xw_b] = visualWse(sig_in, params, N, truncature)
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

[Xw, sg] = dwt(sig_in(1:params.osr:end), params.W, params.order, true);
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
colors = plotColors();
figure("Name", "Comparison time/walsh", "Position", get(0, "ScreenSize"));
axh = gca;

for i=1:nWindows

    startIdx = (i-1)*params.nCoeffs+1;
    endIdx = i*params.nCoeffs;

    sig_Walsh(startIdx:endIdx) = params.W*Xw_b(:,i);
    hold(axh, "off");
    plot(axh, sg(:), "DisplayName", "Time domain signal", "LineWidth", 4, "Color", colors("blue"));
    hold(axh, "on"); grid(axh, "on");
    plot(axh, startIdx:endIdx, sg(:, i), "DisplayName", "Studied part", "LineWidth", 6, "Color", colors("green"));
    plot(axh, sig_Walsh, "DisplayName", "Walsh approx.", "Color", colors("red"), LineWidth=4);
    plot(axh, startIdx:endIdx, sig_Walsh(startIdx:endIdx), "DisplayName", "New sequences", "Color", colors("bordeaux"), LineWidth=6);
    legend(Interpreter="latex", FontSize=22);
    xlim([startIdx - 120 endIdx + 120]);
    xlabel("Samples", Interpreter="latex", FontSize=22);
    
end
% sig_Walsh = repmat(sig_Walsh(1:nWindows*params.nCoeffs), params.osr, 1);
% sig_Walsh = sig_Walsh(:);
end

