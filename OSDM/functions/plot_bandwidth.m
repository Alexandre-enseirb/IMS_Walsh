function [] = plot_bandwidth(sig, freq_axis, bandwidth, export, title_str, fig_id)
%PLOT_BANDWIDTH Summary of this function goes here
%   Detailed explanation goes here

% Par defaut, pas d'export
if ~exist("export","var")
    export = false;
    visibility = "on";
elseif export
    % Les titres c'est caca sur un pdf, donc pas de titre si on exporte
    title_str=false;
    visibility = "off";
else
    visibility = "on"; % dernier cas, si export est deja sur false
end


if ~exist("title_str","var")
    if export
        title_str=false;
    else
        title_str = "Spectre en frequence";
    end
end

if ~exist("fig_id", "var")
    fig_id = logical(false);
end

% Conversion en dB
sig = 20*log10(abs(sig));
sig = sig / max(sig);


bw_visible = min(sig) * ones(size(freq_axis));
bw_visible(freq_axis > bandwidth(1) & freq_axis < bandwidth(2)) = 1; 

% Creation de la figure
if isa(fig_id, "logical")
    fxh = figure(1);%, "Name", "Bandwidth", "Position", get(0, "ScreenSize"), "Visible",visibility);
    
else
    fxh = figure(fig_id);
    
end

% fft en decibels
plot(freq_axis, sig);
hold on, grid on;

% Bande passante
plot(freq_axis, bw_visible, 'LineStyle','--','Color','#77AC30');

% mise en forme des axes
xlabel("frequency","FontSize",22);
ylabel("Amplitude (dB)","FontSize",22);
axh = gca;
axh.FontSize = 22;
xlim([0 params.fWalsh])
axh.YLim(2) = 1.05;
% export si flag
if export
    % Si le fichier existe, demander a l'utilisateur s'il veut le supprimer
    if isfile("untitled.pdf") && ~askforpermission()
        return;
    end
    exportgraphics(axh, "untitled.pdf")
end

% titre si flag
if ~isa(title_str, "logical")
    title(title_str, "FontSize", 22);
end
end

